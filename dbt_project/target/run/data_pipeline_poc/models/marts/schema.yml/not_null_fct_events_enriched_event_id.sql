select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select event_id
from default_default_gold.fct_events_enriched
where event_id is null



      
    ) dbt_internal_test