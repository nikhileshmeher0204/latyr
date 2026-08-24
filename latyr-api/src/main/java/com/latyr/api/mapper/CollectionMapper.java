package com.latyr.api.mapper;

import com.latyr.api.domain.model.Collection;
import org.apache.ibatis.annotations.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Mapper
public interface CollectionMapper {

    @Select("SELECT * FROM collections WHERE id = #{id}")
    Optional<Collection> findById(@Param("id") UUID id);

    @Select("SELECT * FROM collections WHERE code = #{code}")
    Optional<Collection> findByCode(@Param("code") String code);

    @Select("SELECT * FROM collections ORDER BY category ASC, name ASC")
    List<Collection> findAll();

    @Insert("""
        INSERT INTO collections (id, code, name, category, default_icon, feature_triggers, created_at)
        VALUES (COALESCE(#{id}, gen_random_uuid()), #{code}, #{name}, #{category}, #{defaultIcon}, #{featureTriggers}, COALESCE(#{createdAt}, CURRENT_TIMESTAMP))
    """)
    int insert(Collection collection);
}
