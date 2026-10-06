
{% set column_names = [ 
"DURABLE_SUBMISSION_KEY",
"MONTH_KEY",
"FLOW_TYPE_CD",
"LAST_DAY_OF_MONTH_KEY",
"MARKET_DIMENSION_DIM_KEY",
"SOURCE_SYSTEM_DIM_KEY",
"PROFIT_CENTRE_DIM_KEY",
"KEY_PROFIT_CENTRE_DIM_KEY",
"LEGAL_ENTITY_DIM_KEY",
"MANAGEMENT_ENTITY_DIM_KEY",
"CUSTOMER_SEGMENT_DIM_KEY",
"DIM_POLICY_TERM_KEY",
"DIM_BUSINESS_CLASS_KEY",
"FUNCTIONAL_ENTITY_DIM_KEY",
"BUSINESS_UNIT_DIM_KEY",
"DURABLE_CLAIM_BASE_DIM_KEY",
"MTD_LARGE_LOSS_COUNT",
"QTD_LARGE_LOSS_COUNT",
"YTD_LARGE_LOSS_COUNT",
"MTD_POLICY_INFORCE_CNT",
"MTD_BOUND_CNT",
"MTD_SUBMISSION_CNT",
"MTD_QUOTE_CNT",
"QTD_POLICY_INFORCE_CNT",
"QTD_BOUND_CNT",
"QTD_SUBMISSION_CNT",
"QTD_QUOTE_CNT",
"YTD_POLICY_INFORCE_CNT",
"YTD_BOUND_CNT",
"YTD_SUBMISSION_CNT",
"YTD_QUOTE_CNT",
"LOGIC_TYPE_CD",
"DURABLE_AGENT_FED_KEY",
"AGENT_FED_DIM_KEY",
"DURABLE_BROKER_HIERARCHY_KEY",
"BROKER_HIERARCHY_DIM_KEY",
"DIM_PROGRAM_CODE_DESC_KEY",
"BUSINESS_SECTOR_DIM_KEY",
"PRIMARYSI_DIM_KEY",
"POLICY_TERM_CUSTOMER_ASSOC_KEY"
] %} 
{% set summarize = true %} 

{% set a_query %} 
select durable_submission_key||month_key||flow_type_cd as primary_id,
* from  
dev2_it_data_etl_edw_db.dm_vummal.fact_actual_count_old
where month_key = 1521 
and flow_type_cd in ('SUBMISSION_COUNT','QUOTE_COUNT','BOUND_COUNT')
{% endset %} 

{% set b_query %} 
select durable_submission_key||month_key||flow_type_cd as primary_id,
* from  
dev2_it_data_etl_edw_db.dm_vummal.fact_actual_count_new
where month_key = 1521 
and flow_type_cd in ('SUBMISSION_COUNT','QUOTE_COUNT','BOUND_COUNT')
{% endset %} 


{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="primary_id",
  column_to_compare=column_name
) %}


{% if loop.first %}

with main as ( 

{% endif %}

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

