
{% set column_names = [
"CREATEDBY",
"CREATEDBYNAME",
"CREATEDBYYOMINAME",
"CREATEDON",
"CREATEDONBEHALFBY",
"CREATEDONBEHALFBYNAME",
"CREATEDONBEHALFBYYOMINAME",
"IMPORTSEQUENCENUMBER",
"MODIFIEDBY",
"MODIFIEDBYNAME",
"MODIFIEDBYYOMINAME",
"MODIFIEDON",
"MODIFIEDONBEHALFBY",
"MODIFIEDONBEHALFBYNAME",
"MODIFIEDONBEHALFBYYOMINAME",
"NEW_AUTOMATIC_DECLINE_IND",
"NEW_BUSINESS_SECTOR_CD",
"NEW_ELIGIBLE_FOR_SMALL_BUSINESS_IND",
"NEW_HAZARD_GRADE_CD",
"NEW_IBC_CD",
"NEW_IBC_CDNAME",
"NEW_INDUSTRY_CODEID",
"NEW_INITIATING_SOURCE_SYSTEM_CD",
"NEW_KEY_WORDS_ENGLISH",
"NEW_KEY_WORDS_FRENCH",
"NEW_NAME",
"NEW_NBFC_INDUSTRY_CD",
"NEW_NBFC_INDUSTRY_CODE_CATEGORY_CD",
"NEW_NBFC_INDUSTRY_CODE_ENGLISH_DESC",
"NEW_NBFC_INDUSTRY_CODE_FRENCH_DESC",
"NEW_OPERATIONSINDUSTRYCODEID",
"NEW_OPERATIONSINDUSTRYCODEIDNAME",
"NEW_SMALL_BUSINESS_MAX_REVENUE_AMT",
"NEW_UW_INITIAL_MARKET_DIMENSION_CD",
"OVERRIDDENCREATEDON",
"OWNERID",
"OWNERIDNAME",
"OWNERIDTYPE",
"OWNERIDYOMINAME",
"OWNINGBUSINESSUNIT",
"OWNINGTEAM",
"OWNINGUSER",
"STATECODE",
"STATUSCODE",
"TIMEZONERULEVERSIONNUMBER",
"UTCCONVERSIONTIMEZONECODE"
] %}
{% set summarize = true %}

{% set a_query %}      
SELECT * FROM STG.ST_D365_NEW_INDUSTRY_CODE
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_INDUSTRY_CODEID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}


{% set b_query %}
SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDNEW_INDUSTRY_CODE
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_INDUSTRY_CODEID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="NEW_INDUSTRY_CODEID",
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

