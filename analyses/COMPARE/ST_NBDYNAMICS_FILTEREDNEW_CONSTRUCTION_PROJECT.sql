
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
"NEW_CITY",
"NEW_CONSTRUCTION_PROJECTID",
"NEW_COUNTRY",
"NEW_LEGACY_ADDRESS_1",
"NEW_LEGACY_ADDRESS_2",
"NEW_NAME",
"NEW_POSTAL_CODE",
"NEW_PO_BOX",
"NEW_PROVINCE",
"NEW_RR",
"NEW_STREET_DIRECTION",
"NEW_STREET_NAME",
"NEW_STREET_NUMBER",
"NEW_STREET_TYPE",
"NEW_SUBMISSION_ID",
"NEW_SUITE_UNIT",
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
"TRAVERSEDPATH",
"UTCCONVERSIONTIMEZONECODE"
] %}
{% set summarize = true %}

{% set a_query %}      
SELECT * FROM STG.ST_D365_NEW_CONSTRUCTION_PROJECT
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_CONSTRUCTION_PROJECTID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}


{% set b_query %}
SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDNEW_CONSTRUCTION_PROJECT
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_CONSTRUCTION_PROJECTID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="NEW_CONSTRUCTION_PROJECTID",
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

