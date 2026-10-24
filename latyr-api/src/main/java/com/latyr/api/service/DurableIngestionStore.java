package com.latyr.api.service;

import com.latyr.api.domain.model.IngestionJob;
import com.latyr.api.exception.AnalysisOutcomeUnknownException;
import com.latyr.api.exception.IngestionLeaseLostException;
import com.latyr.api.mapper.IngestionJobMapper;
import com.latyr.api.mapper.IngestionStageMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Service
public class DurableIngestionStore {
    private static final Set<String> STAGES = Set.of("SOURCE", "MEDIA", "ANALYSIS", "ENRICHMENT");
    private final IngestionJobMapper jobs;
    private final IngestionStageMapper stages;
    private final TransactionTemplate transactions;

    public DurableIngestionStore(IngestionJobMapper jobs, IngestionStageMapper stages, PlatformTransactionManager manager) {
        this.jobs = jobs;
        this.stages = stages;
        this.transactions = new TransactionTemplate(manager);
    }

    public Optional<IngestionJob> claim(String workerId, int leaseSeconds) {
        if (leaseSeconds < 1) throw new IllegalArgumentException("Lease duration must be positive");
        return transactions.execute(status -> {
            for (IngestionJob candidate : jobs.findClaimCandidates()) {
                jobs.ensureSourceLease(candidate.getCanonicalSourceId());
                UUID token = UUID.randomUUID();
                if (jobs.acquireSourceLease(candidate, token, leaseSeconds) != 1) continue;
                stages.expireAttempts(candidate);
                stages.expireCheckpoints(candidate);
                jobs.claimLockedJob(candidate.getId(), workerId, token, leaseSeconds);
                return jobs.findById(candidate.getId());
            }
            return Optional.empty();
        });
    }

    public void withLease(IngestionJob job, Runnable action) {
        transactions.executeWithoutResult(status -> {
            requireLease(job);
            action.run();
        });
    }

    private void requireLease(IngestionJob job) {
        if (job.getLeaseToken() == null || jobs.lockCurrentLease(job).isEmpty()
                || jobs.lockCurrentSourceLease(job).isEmpty()) throw new IngestionLeaseLostException();
    }

    public boolean renew(IngestionJob job, int leaseSeconds) {
        if (leaseSeconds < 1) throw new IllegalArgumentException("Lease duration must be positive");
        try {
            withLease(job, () -> {
                if (jobs.renewJob(job, leaseSeconds) != 1 || jobs.renewSource(job, leaseSeconds) != 1)
                    throw new IngestionLeaseLostException();
            });
            return true;
        } catch (IngestionLeaseLostException lost) {
            return false;
        }
    }

    public Map<String,Object> loadCheckpoint(IngestionJob job, String stage) {
        checkStage(stage);
        return transactions.execute(status -> {
            requireLease(job);
            return stages.find(job, stage).filter(checkpoint -> "COMPLETED".equals(checkpoint.getStatus()))
                .map(checkpoint -> checkpoint.getOutput()).orElse(null);
        });
    }

    public void startStage(IngestionJob job, String stage) {
        checkStage(stage);
        withLease(job, () -> {
            var prior = stages.find(job, stage);
            if ("ANALYSIS".equals(stage) && (job.isRecoveryAmbiguous()
                    || prior.filter(checkpoint -> Set.of("RUNNING", "AMBIGUOUS").contains(checkpoint.getStatus())).isPresent()))
                throw new AnalysisOutcomeUnknownException();
            if (stages.start(job, stage) != 1) throw new IllegalStateException("Completed checkpoints are immutable");
            stages.startAttempt(job, stage);
        });
    }

    public void completeStage(IngestionJob job, String stage, Map<String,Object> output) {
        checkStage(stage);
        withLease(job, () -> {
            if (stages.end(job, stage, "COMPLETED", output, null) != 1)
                throw new IllegalStateException("Stage must be running under the current lease");
            stages.endAttempt(job, stage, "COMPLETED", null);
        });
    }

    public void failStage(IngestionJob job, String stage, String errorCode) {
        checkStage(stage);
        withLease(job, () -> {
            String outcome = errorCode != null && (errorCode.startsWith("AMBIGUOUS") || errorCode.equals("AI_OUTCOME_UNKNOWN"))
                ? "AMBIGUOUS" : "FAILED";
            stages.end(job, stage, outcome, null, safeCode(errorCode));
            stages.endAttempt(job, stage, outcome, safeCode(errorCode));
        });
    }

    public void complete(IngestionJob job) {
        finish(job, "COMPLETED", null, 0, 0);
    }

    public boolean retryOrFail(IngestionJob job, boolean retryable, String errorCode) {
        boolean terminal = !retryable || job.getAttemptCount() >= job.getMaxAttempts();
        int backoff = Math.min(900, 15 * (1 << Math.min(6, Math.max(0, job.getAttemptCount() - 1))));
        finish(job, terminal ? "FAILED" : "PENDING", safeCode(errorCode), terminal ? 0 : backoff, 0);
        return terminal;
    }

    public void releaseClaim(IngestionJob job) {
        finish(job, "PENDING", "EXECUTOR_REJECTED", 0, 1);
    }

    private void finish(IngestionJob job, String status, String errorCode, int delay, int undoAttempt) {
        withLease(job, () -> {
            if (jobs.finishLease(job, status, errorCode, delay, undoAttempt) != 1)
                throw new IngestionLeaseLostException();
            jobs.releaseSourceLease(job);
        });
    }

    private static void checkStage(String stage) {
        if (!STAGES.contains(stage)) throw new IllegalArgumentException("Unknown ingestion stage");
    }

    private static String safeCode(String code) {
        return code != null && code.matches("[A-Z][A-Z0-9_]{0,127}") ? code : "PROCESSING_FAILED";
    }
}
