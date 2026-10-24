package com.latyr.api.support;

import org.apache.ibatis.session.Configuration;
import org.flywaydb.core.Flyway;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.transaction.support.TransactionTemplate;

import javax.sql.DataSource;
import java.util.UUID;

/** An isolated generated schema, never a development database wipe. */
public final class PostgresTestDatabase implements AutoCloseable {
    private final String schema = "latyr_test_" + UUID.randomUUID().toString().replace("-", "");
    private final DataSource admin;
    private final DataSource dataSource;
    private final DataSourceTransactionManager manager;
    private final JdbcTemplate jdbc;
    private final SqlSessionTemplate sessions;

    public PostgresTestDatabase() throws Exception {
        this(null);
    }

    public PostgresTestDatabase(String target) throws Exception {
        String url = System.getenv("TEST_DATABASE_URL");
        if (url == null || url.isBlank()) throw new IllegalStateException("TEST_DATABASE_URL is required for PostgreSQL verification");
        admin = new DriverManagerDataSource(url);
        new JdbcTemplate(admin).execute("CREATE SCHEMA " + schema);
        dataSource = new DriverManagerDataSource(url + (url.contains("?") ? "&" : "?") + "currentSchema=" + schema);
        migrate(target);
        manager = new DataSourceTransactionManager(dataSource);
        jdbc = new JdbcTemplate(dataSource);
        SqlSessionFactoryBean factory = new SqlSessionFactoryBean();
        factory.setDataSource(dataSource);
        factory.setTypeHandlersPackage("com.latyr.api.config.typehandler");
        Configuration configuration = new Configuration();
        configuration.setMapUnderscoreToCamelCase(true);
        factory.setConfiguration(configuration);
        sessions = new SqlSessionTemplate(factory.getObject());
    }

    public void migrate(String target) {
        var configuration = Flyway.configure().dataSource(dataSource).schemas(schema).defaultSchema(schema);
        if (target != null) configuration.target(target);
        configuration.load().migrate();
    }

    public <T> T mapper(Class<T> type) {
        var configuration = sessions.getConfiguration();
        if (!configuration.hasMapper(type)) configuration.addMapper(type);
        return sessions.getMapper(type);
    }

    public JdbcTemplate jdbc() { return jdbc; }
    public DataSource dataSource() { return dataSource; }
    public DataSourceTransactionManager manager() { return manager; }
    public TransactionTemplate transactions() { return new TransactionTemplate(manager); }

    @Override
    public void close() {
        if (!schema.matches("latyr_test_[a-f0-9]{32}")) throw new IllegalStateException("Invalid test schema");
        new JdbcTemplate(admin).execute("DROP SCHEMA " + schema + " CASCADE");
    }
}
