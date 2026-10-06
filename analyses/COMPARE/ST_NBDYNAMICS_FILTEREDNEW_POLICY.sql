
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
"NEW_AGENCY",
"NEW_AGENCYNAME",
"NEW_BILL_TO_COUNTRY",
"NEW_BROKERAGE",
"NEW_BROKERAGENAME",
"NEW_CITY",
"NEW_COUNTRY",
"NEW_COURSE_OF_CONSTRUCTION_IND",
"NEW_CUSTOMER_ID",
"NEW_CUSTOMER_IDNAME",
"NEW_CUSTOMER_IDYOMINAME",
"NEW_EXTERNAL_POLICY_REFERENCE_ID",
"NEW_FULL_TERM_PREMIUM_AMT",
"NEW_FULL_TERM_PREMIUM_AMT_BASE",
"NEW_IFIS_SUBMISSION_NUMBER_ID",
"NEW_INITIAL_BOUND_PREMIUM_AMT",
"NEW_INITIAL_BOUND_PREMIUM_AMT_BASE",
"NEW_INSURED_NAME",
"NEW_LEGACY_POLICY_PRODUCT",
"NEW_LEGACY_STREET1",
"NEW_LEGACY_STREET2",
"NEW_LEGAL_ENTITY",
"NEW_LEGAL_ENTITYNAME",
"NEW_MAIL_ADDRESS_PO_BOX",
"NEW_MAIL_ADDRESS_RR",
"NEW_MAIL_ADDRESS_STREET_DIRECTION",
"NEW_MAIL_ADDRESS_STREET_NAME",
"NEW_MAIL_ADDRESS_STREET_NUMBER",
"NEW_MAIL_ADDRESS_STREET_TYPE",
"NEW_MAIL_ADDRESS_SUITE_UNIT",
"NEW_MR_POLICY_ID",
"NEW_MR_SUBMISSION_ID",
"NEW_NAME",
"NEW_OPPORTUNITY_ID",
"NEW_OPPORTUNITY_IDNAME",
"NEW_POLICYID",
"NEW_POLICY_EFFECTIVE_DATE",
"NEW_POLICY_EXPIRY_DATE",
"NEW_POLICY_NUMBER",
"NEW_POLICY_STATUS_CD",
"NEW_POLICY_STATUS_REASON_CD",
"NEW_POLICY_UNDERWRITER_ID",
"NEW_POLICY_UNDERWRITER_IDNAME",
"NEW_POLICY_UNDERWRITER_IDYOMINAME",
"NEW_POLICY_VERSION",
"NEW_POSTAL_CODE",
"NEW_PRIMARY_QUOTE_ID",
"NEW_PRIMARY_QUOTE_IDNAME",
"NEW_PROJECT_NAME",
"NEW_PROJECT_NAMENAME",
"NEW_PROVINCE_CD",
"NEW_SOURCE_SYSTEM_POLICY_KEY",
"NEW_UW_PLATFORM",
"NEW_WRITTEN_PREMIUM_AMT",
"NEW_WRITTEN_PREMIUM_AMT_BASE",
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
SELECT * FROM STG.ST_D365_NEW_POLICY
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_POLICYID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}


{% set b_query %}
SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDNEW_POLICY
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_POLICYID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="NEW_POLICYID",
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

