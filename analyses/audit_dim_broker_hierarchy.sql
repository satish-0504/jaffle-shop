{% set column_names = [
    "BROKER_CORPORATE_CD",
    "BROKER_CORPORATE_DIM_KEY",
    "DURABLE_BROKER_CORPORATE_DIM_KEY",
    "BROKER_AGENCY_DIM_KEY",
    "BROKER_ID",
    "DURABLE_BROKER_AGENCY_DIM_KEY",
    "BROKER_LOCATION_CD",
    "BROKER_LOCATION_DIM_KEY",
    "BROKER_LOCATION_NAME",
    "DURABLE_BROKER_LOCATION_DIM_KEY",
    "BROKER_MASTER_CD",
    "BROKER_MASTER_DIM_KEY",
    "BROKER_MASTER_LEGAL_NAME",
    "BROKER_MASTER_NAME",
    "DURABLE_BROKER_MASTER_DIM_KEY",
    "BROKER_NAME",
    "BROKER_PARTNER_LEVEL_TYPE_CD",
    "BROKER_PARTNER_LEVEL_TYPE_ENG_DESC",
    "CURRENT_IND",
    "EFFECTIVE_END_TS"
] %}
{% set summarize = true %}



{% set a_query %}      
SELECT  BAD.AGENCY_CD as primary_id,
BCD.CORPORATE_GROUP_CODE AS BROKER_CORPORATE_CD
,BCD.BROKER_CORPORATE_DIM_KEY AS BROKER_CORPORATE_DIM_KEY
,BCD.DURABLE_BROKER_CORPORATE_KEY AS DURABLE_BROKER_CORPORATE_DIM_KEY

,BAD.BROKER_AGENCY_DIM_KEY AS BROKER_AGENCY_DIM_KEY
,BAD.AGENCY_CD AS BROKER_ID
,BAD.DURABLE_BROKER_AGENCY_DIM_KEY AS DURABLE_BROKER_AGENCY_DIM_KEY

,BLD.BROKER_LOCATION_CD AS BROKER_LOCATION_CD
,BLD.BROKER_LOCATION_DIM_KEY AS BROKER_LOCATION_DIM_KEY
,RTRIM(BLD.BROKER_LOCATION_NAME) AS BROKER_LOCATION_NAME
,BLD.DURABLE_BROKER_LOCATION_KEY AS DURABLE_BROKER_LOCATION_DIM_KEY

,BMD.BROKER_MASTER_CD AS BROKER_MASTER_CD
,BMD.BROKER_MASTER_DIM_KEY AS BROKER_MASTER_DIM_KEY
,BMD.BROKER_LEGAL_NAME AS BROKER_MASTER_LEGAL_NAME
,BMD.BROKER_MASTER_NAME AS BROKER_MASTER_NAME

,BMD.DURABLE_BROKER_MASTER_KEY AS DURABLE_BROKER_MASTER_DIM_KEY
,BCD.BROKER_NAME AS BROKER_NAME
,BCD.BROKER_PARTNER_LEVEL_TYPE_CD AS BROKER_PARTNER_LEVEL_TYPE_CD
,BCD.BROKER_PARTNER_LEVEL_TYPE_ENG_DESC AS BROKER_PARTNER_LEVEL_TYPE_ENG_DESC


,BCD.CURRENT_IND
,BCD.EFFECTIVE_END_TS
-- ,BCD.EFFECTIVE_START_TS
-- ,GREATEST_IGNORE_NULLS(
--    BCD.EFFECTIVE_START_TS,
--    BMD.EFFECTIVE_START_TS,
--    BLD.EFFECTIVE_START_TS,
--    BAD.EFFECTIVE_START_TS
-- ) AS EFFECTIVE_START_TS

 FROM
DM.BROKER_CORPORATE_DIM BCD
 JOIN DM.BROKER_MASTER_DIM BMD
ON BCD.CORPORATE_GROUP_CODE = BMD.CORPORATE_GROUP_CODE
AND bcd.current_ind ='Y'AND BMD.current_ind ='Y'
  JOIN DM.BROKER_LOCATION_DIM BLD
ON BMD.BROKER_MASTER_CD = BLD.BROKER_MASTER_CODE
 AND BLD.current_ind ='Y'
 JOIN DM.BROKER_AGENCY_DIM BAD
ON BLD.BROKER_LOCATION_CD = BAD.BROKER_LOCATION_CD
 and BAD.current_ind ='Y' 
{% endset %}



{% set b_query %}
SELECT BROKER_ID as primary_id,
BROKER_CORPORATE_CD
,BROKER_CORPORATE_DIM_KEY
,DURABLE_BROKER_CORPORATE_DIM_KEY
,BROKER_AGENCY_DIM_KEY
,BROKER_ID
-- ,PMS_AGENCY_CD
,DURABLE_BROKER_AGENCY_DIM_KEY
,BROKER_LOCATION_CD
,BROKER_LOCATION_DIM_KEY
,TRIM(BROKER_LOCATION_NAME) AS BROKER_LOCATION_NAME
,DURABLE_BROKER_LOCATION_DIM_KEY
,BROKER_MASTER_CD
,BROKER_MASTER_DIM_KEY
,BROKER_MASTER_LEGAL_NAME
,BROKER_MASTER_NAME

,DURABLE_BROKER_MASTER_DIM_KEY
,BROKER_NAME
,BROKER_PARTNER_LEVEL_TYPE_CD
,BROKER_PARTNER_LEVEL_TYPE_ENG_DESC

,CURRENT_IND
,EFFECTIVE_END_TS
-- ,EFFECTIVE_START_TS

FROM DM.DIM_BROKER_HIERARCHY  
WHERE CURRENT_IND='Y' AND 
BROKER_CORPORATE_CD > '0' 
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

