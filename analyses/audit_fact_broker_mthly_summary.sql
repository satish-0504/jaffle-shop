
{% set column_names = [
      "month_key"
    , "functional_entity_dim_key"
    , "business_type_dim_key"
    , "market_dimension_dim_key"
    , "customer_segment_dim_key"
    , "business_sector_dim_key"
    , "line_of_business_dim_key"
    , "durable_broker_hierarchy_key"
    , "currency_dim_key"
    , "agency_code"
    , "dim_policy_term_key"
    , "policy_number"
    , "policy_term_number"
    , "policy_effective_date"
    , "policy_expiry_date"
    , "dim_program_code_desc_key"
    , "cfib_indicator"
    , "ytd_gross_written_premium_amt"
    , "ytd_gross_earned_premium_amt"
    , "ytd_cancelled_premium_amt"
    , "ytd_lapsed_premium_amt"
    , "ytd_new_business_written_premium_amt"
    , "ytd_commission_amt"
    , "cancelled_flg"
    , "lapsed_flg"
    , "nb_policy_flg"
    , "renewable_flg"
    , "retention_flg"
    , "ytd_renewable_premium_amt"
    , "ytd_retention_premium_amt"
    , "policy_count"
    , "submission_count"
    , "quoted_count"
    , "bounded_count"
    , "inforce_flg"
    , "ytd_total_case_loss_incurred_amt"
    , "ytd_losses_amt"
    , "ytd_inforce_premium_amt"
] %}
{% set summarize = true %}

{% set a_query %}      
	select 
	concat_ws('|' , month_key, dim_policy_term_key, line_of_business_dim_key, market_dimension_dim_key, currency_dim_key) as primary_id,
    month_key
    , functional_entity_dim_key
    , business_type_dim_key
    , market_dimension_dim_key
    , customer_segment_dim_key
    , business_sector_dim_key
    , line_of_business_dim_key
    , durable_broker_hierarchy_key
    , currency_dim_key
    , agency_code
    , dim_policy_term_key
    , policy_number
    , policy_term_number
    , policy_effective_date
    , policy_expiry_date
    , dim_program_code_desc_key
    , cfib_indicator
    , ytd_gross_written_premium_amt
    , ytd_gross_earned_premium_amt
    , ytd_cancelled_premium_amt
    , ytd_lapsed_premium_amt
    , ytd_new_business_written_premium_amt
    , ytd_commission_amt
    , cancelled_flg
    , lapsed_flg
    , nb_policy_flg
    , renewable_flg
    , retention_flg
    , ytd_renewable_premium_amt
    , ytd_retention_premium_amt
    , policy_count
    , submission_count
    , quoted_count
    , bounded_count
    , inforce_flg
    , ytd_total_case_loss_incurred_amt
    , ytd_losses_amt
    ,ytd_inforce_premium_amt
from qa2_it_data_etl_edw_db.dm.fact_broker_mthly_summary 
--from dev2_it_data_etl_edw_db.dm.fact_broker_mthly_summary 
where month_key = 1513 
and policy_number <> '_NA_EDW' and cancelled_flg <> '-2'
{% endset %}

{% set b_query %}
	select 
	concat_ws('|' , month_key, dim_policy_term_key, line_of_business_dim_key, market_dimension_dim_key, currency_dim_key) as primary_id,
    month_key
    , functional_entity_dim_key
    , business_type_dim_key
    , market_dimension_dim_key
    , customer_segment_dim_key
    , business_sector_dim_key
    , line_of_business_dim_key
    , durable_broker_hierarchy_key
    , currency_dim_key
    , agency_code
    , dim_policy_term_key
    , policy_number
    , policy_term_number
    , policy_effective_date
    , policy_expiry_date
    , dim_program_code_desc_key
    , cfib_indicator
    , ytd_gross_written_premium_amt
    , ytd_gross_earned_premium_amt
    , ytd_cancelled_premium_amt
    , ytd_lapsed_premium_amt
    , ytd_new_business_written_premium_amt
    , ytd_commission_amt
    , cancelled_flg
    , lapsed_flg
    , nb_policy_flg
    , renewable_flg
    , retention_flg
    , ytd_renewable_premium_amt
    , ytd_retention_premium_amt
    , policy_count
    , submission_count
    , quoted_count
    , bounded_count
    , inforce_flg
    , ytd_total_case_loss_incurred_amt
    , ytd_losses_amt
    ,ytd_inforce_premium_amt
-- from qa2_it_data_etl_edw_db.dm.fact_broker_mthly_summary 
from dev2_it_data_etl_edw_db.dm.fact_broker_mthly_summary 
where month_key = 1513 
and policy_number <> '_NA_EDW' and cancelled_flg <> '-2'
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="primary_id",
  column_to_compare=column_name
) %}

/*  Create a query combining results from all columns so that the user, or the test suite, can examine all at once. */

{% if loop.first %}

/*  Create a CTE that wraps all the unioned subqueries that are created	in this for loop */
  with main as ( 

{% endif %}

/*  There will be one audit_query subquery for each column */
( {{ audit_query }} )

{% if not loop.last %}

  union all

{% else %}

), 

  {%- if summarize %}

	final as (
	  select
		upper(column_name) as column_name,
		sum(case when conflicting_values then 1 else 0 end) as conflicting_values,
		sum(case when perfect_match then 1 else 0 end) as perfect_match,
		sum(case when null_in_a then 1 else 0 end) as nulls_in_source,
		sum(case when null_in_b then 1 else 0 end) as nulls_in_target,
		sum(case when missing_from_a then 1 else 0 end) as missing_from_source,
		sum(case when missing_from_b then 1 else 0 end) as missing_from_target
	  from main
	  group by 1
	  order by column_name
	)

  {%- else %}

	final as (
	  select
		primary_key,           
		upper(column_name) as column_name,
		conflicting_values,
		perfect_match,
		nulls_in_source,
		nulls_in_target,
		missing_from_source,
		missing_from_target
	  from main    
	  order by primary_key
	)

  {%- endif %}

  select * from final 
  order by conflicting_values desc;

{% endif %}

{% endfor %}

