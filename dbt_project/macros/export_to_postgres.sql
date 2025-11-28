{% macro export_to_postgres(source_table, target_table, postgres_config) %}
    {#
    Macro pour exporter une table Spark vers PostgreSQL
    
    Args:
        source_table: Nom de la table source (ex: 'gold.gold_mart_uemoa_monetary_dashboard')
        target_table: Nom de la table cible dans PostgreSQL (ex: 'gold_mart_uemoa_monetary_dashboard')
        postgres_config: Configuration PostgreSQL (dict avec host, port, database, user, password)
    #}
    
    {% set jdbc_url = "jdbc:postgresql://" ~ postgres_config.host ~ ":" ~ postgres_config.port ~ "/" ~ postgres_config.database %}
    
    -- Exporter vers PostgreSQL via JDBC
    INSERT OVERWRITE TABLE {{ target_table }}
    SELECT * FROM {{ source_table }};
    
{% endmacro %}
