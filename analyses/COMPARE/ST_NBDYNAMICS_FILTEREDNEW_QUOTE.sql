
{% set column_names = [ 
"CREATEDBY",
"CREATEDBYNAME",
"CREATEDBYYOMINAME",
"CREATEDON",
"CREATEDONBEHALFBY",
"CREATEDONBEHALFBYNAME",
"CREATEDONBEHALFBYYOMINAME",
"EXCHANGERATE",
"IMPORTSEQUENCENUMBER",
"MODIFIEDBY",
"MODIFIEDBYNAME",
"MODIFIEDBYYOMINAME",
"MODIFIEDON",
"MODIFIEDONBEHALFBY",
"MODIFIEDONBEHALFBYNAME",
"MODIFIEDONBEHALFBYYOMINAME",
"NEW_ADD_QUOTE_ID",
"NEW_ADD_QUOTE_IDNAME",
"NEW_AGENCY_CODE",
"NEW_AGENCY_CODENAME",
"NEW_BROKERAGE",
"NEW_BROKERAGENAME",
"NEW_COMPETITORS_QUOTE",
"NEW_COMPETITORS_QUOTE_BASE",
"NEW_COMPONENT",
"NEW_COMPONENTNAME",
"NEW_COURSE_CONSTRUCTION_IND",
"NEW_CUSTOMER_ID",
"NEW_CUSTOMER_IDNAME",
"NEW_CUSTOMER_IDYOMINAME",
"NEW_DESCRIPTION",
"NEW_EFFECTIVE_FROM",
"NEW_EFFECTIVE_TO",
"NEW_EXPIRES_ON",
"NEW_EXTERNAL_SYSTEM_QUOTE_ID",
"NEW_FREIGHT_TERMS_CD",
"NEW_LEGAL_ENTITY",
"NEW_LEGAL_ENTITYNAME",
"NEW_LOST_TO_CARRIER_CD",
"NEW_LOST_TO_CARRIER_CDNAME",
"NEW_LOST_TO_CARRIER_CDYOMINAME",
"NEW_MR_QUOTE_ID",
"NEW_MR_SUBMISSION_ID",
"NEW_NAME",
"NEW_OPPORTUNITY_ID",
"NEW_OPPORTUNITY_IDNAME",
"NEW_PAYMENT_TERMS_CD",
"NEW_PROCESSED",
"NEW_PROJECT_ID",
"NEW_PROJECT_IDNAME",
"NEW_PROPOSED_POLICY_EFFECTIVE_DT",
"NEW_PROPOSED_POLICY_EXPIRY_DT",
"NEW_QUOTED_PREMIUM_AMT",
"NEW_QUOTED_PREMIUM_AMT_BASE",
"NEW_QUOTED_UNDERWRITING_PLATFORM",
"NEW_QUOTEID",
"NEW_QUOTE_ID",
"NEW_QUOTE_STATUS_CD",
"NEW_QUOTE_STATUS_REASON_CD",
"NEW_QUOTE_UNDERWRITER",
"NEW_QUOTE_UNDERWRITERNAME",
"NEW_QUOTE_UNDERWRITERYOMINAME",
"NEW_REQUESTED_DELIVERY_BY",
"NEW_REVISION_ID",
"OVERRIDDENCREATEDON",
"OWNERID",
"OWNERIDNAME",
"OWNERIDTYPE",
"OWNERIDYOMINAME",
"OWNINGBUSINESSUNIT",
"OWNINGTEAM",
"OWNINGUSER",
"PROCESSID",
"STAGEID",
"STATECODE",
"STATUSCODE",
"TIMEZONERULEVERSIONNUMBER",
"TRANSACTIONCURRENCYID",
"TRANSACTIONCURRENCYIDNAME",
"TRAVERSEDPATH",
"UTCCONVERSIONTIMEZONECODE"
] %} 
{% set summarize = true %} 

{% set a_query %} 
SELECT * FROM STG.ST_D365_NEW_QUOTE
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_QUOTEID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %} 

{% set b_query %} 
SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDNEW_QUOTE
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_QUOTEID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %} 


{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="NEW_QUOTEID",
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

