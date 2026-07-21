package com.tuowei.dazhongdianping.module.search.mapper;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
class SearchIndexMapperTest {

    @Autowired
    private SearchIndexMapper searchIndexMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @ParameterizedTest(name = "disabled {0} must exclude its shops from search indexing")
    @MethodSource("disabledGeoUpdates")
    void shouldExcludeShopsWithDisabledGeoFromRebuildAndSingleShopQueries(String geoType, String updateSql) {
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM shop WHERE id=20002 AND status=1 AND is_deleted=FALSE",
                Integer.class)).isEqualTo(1);

        jdbcTemplate.update(updateSql);

        assertThat(searchIndexMapper.selectActiveShop(20002L)).isNull();
        assertThat(searchIndexMapper.selectActiveShops())
                .extracting(row -> row.getId())
                .doesNotContain(20002L);
    }

    private static Stream<Arguments> disabledGeoUpdates() {
        return Stream.of(
                Arguments.of("category", "UPDATE category SET status=0 WHERE id=202"),
                Arguments.of("city", "UPDATE city SET status=0 WHERE id=102"),
                Arguments.of("area", "UPDATE area SET status=0 WHERE id=1021")
        );
    }
}
