
{% set column_names = ["EFFECTIVE_START_TS", "EFFECTIVE_END_TS", "CURRENT_IND" ] %}
{% set summarize = true %}

{% set a_query %}      
	select concat_ws('|' , dim_policy_term_durable_key, new_business_ind, cancelled_ind, lapsed_ind) as primary_id,
	* exclude(dim_broker_policy_status_work_key, create_ts, last_update_ts, create_process_group_log_key, last_update_process_group_log_key, dbt_unique_key)
	from QA2_IT_DATA_ETL_EDW_DB.DM.DIM_BROKER_POLICY_STATUS_WORK_20260722_1
{% endset %}

{% set b_query %}
	select concat_ws('|' , dim_policy_term_durable_key, new_business_ind, cancelled_ind, lapsed_ind) as primary_id,
	* exclude(dim_broker_policy_status_work_key, create_ts, last_update_ts, create_process_group_log_key, last_update_process_group_log_key, dbt_unique_key)
	from QA2_IT_DATA_ETL_EDW_DB.DM.DIM_BROKER_POLICY_STATUS_WORK
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

