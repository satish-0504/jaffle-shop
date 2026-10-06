
{% set column_names = [
"ACTUALEND",
"ACTUALSTART",
"BUDGETEDCOST",
"BUDGETEDCOST_BASE",
"CAMPAIGNID",
"CODENAME",
"CREATEDBY",
"CREATEDBYNAME",
"CREATEDBYYOMINAME",
"CREATEDON",
"CREATEDONBEHALFBY",
"CREATEDONBEHALFBYNAME",
"CREATEDONBEHALFBYYOMINAME",
"DESCRIPTION",
"ENTITYIMAGEID",
"ENTITYIMAGE_TIMESTAMP",
"ENTITYIMAGE_URL",
"EXCHANGERATE",
"EXPECTEDRESPONSE",
"EXPECTEDREVENUE",
"EXPECTEDREVENUE_BASE",
"IMPORTSEQUENCENUMBER",
"ISTEMPLATE",
"MESSAGE",
"MODIFIEDBY",
"MODIFIEDBYNAME",
"MODIFIEDBYYOMINAME",
"MODIFIEDON",
"MODIFIEDONBEHALFBY",
"MODIFIEDONBEHALFBYNAME",
"MODIFIEDONBEHALFBYYOMINAME",
"NAME",
"NEW_ACTUAL_BOUND",
"NEW_ACTUAL_NOT_BOUND",
"NEW_ACTUAL_NOT_QUOTED",
"NEW_ACTUAL_QUOTES",
"NEW_ACTUAL_SUBMISSIONS",
"NEW_ADDITIONAL_PRODUCERS",
"NEW_APPOINTMENTS_SCHEDULED_TOTAL",
"NEW_AVERAGEPREMIUMPERPROSPECT",
"NEW_AVERAGEPREMIUMPERPROSPECT_BASE",
"NEW_AVERAGE_QUOTE_TIME",
"NEW_AVERAGE_TIME_TO_BIND",
"NEW_BROKERAGE",
"NEW_BROKERAGENAME",
"NEW_BUSINESSDEVELOPMENTMANAGER",
"NEW_BUSINESSDEVELOPMENTMANAGERNAME",
"NEW_BUSINESSDEVELOPMENTMANAGERYOMINAME",
"NEW_BUSINESSSECTOR",
"NEW_CAMPAIGN_COMPLETED_DATE",
"NEW_CAMPAIGN_POTENTIAL_TOTAL",
"NEW_CAMPAIGN_POTENTIAL_TOTAL_BASE",
"NEW_CONTACTED_PROSPECTS_TOTAL",
"NEW_FINAL_EXPIRY_DATE_TOTAL",
"NEW_FINAL_HIT_RATIO",
"NEW_GEOGRAPHYOFCAMPAIGN",
"NEW_GWP",
"NEW_GWP_BASE",
"NEW_LAUNCH_DATE",
"NEW_MANAGEMENTENTITY",
"NEW_NUMBEROFPROSPECTS",
"NEW_NUMBER_OF_APPOINTMENTS_SCHEDULED",
"NEW_NUMBER_OF_COLD_LEADS",
"NEW_NUMBER_OF_DEAD_LEADS",
"NEW_NUMBER_OF_FUTURE_EXPIRY_DATES",
"NEW_NUMBER_OF_PAST_EXPIRY_DATES",
"NEW_PLANQUOTERATIO",
"NEW_PLANSUBMISSIONRATIO",
"NEW_PLANTOTALPREMIUM",
"NEW_PLANTOTALPREMIUM_BASE",
"NEW_PLAN_BOUND_RATIO",
"NEW_PLAN_EXPIRY_DATE_RATIO",
"NEW_PROGRAMCODE",
"NEW_PROSPECTS_IN_CAMPAIGN",
"NEW_REGION",
"NEW_RISKSEGMENT",
"NEW_SALESINITIATIVECODE",
"NEW_SUB_QUOTE_RATIO",
"NEW_TARGETCLASS",
"NEW_TARGETCUSTOMERSIZEREVENUE",
"NEW_TELEMARKETER",
"NEW_UNDERWRITER",
"NEW_UNDERWRITERNAME",
"NEW_UNDERWRITERYOMINAME",
"OBJECTIVE",
"OTHERCOST",
"OTHERCOST_BASE",
"OVERRIDDENCREATEDON",
"OWNERID",
"OWNERIDNAME",
"OWNERIDTYPE",
"OWNERIDYOMINAME",
"OWNINGBUSINESSUNIT",
"OWNINGTEAM",
"OWNINGUSER",
"PRICELISTID",
"PRICELISTNAME",
"PROCESSID",
"PROMOTIONCODENAME",
"PROPOSEDEND",
"PROPOSEDSTART",
"STAGEID",
"STATECODE",
"STATUSCODE",
"TIMEZONERULEVERSIONNUMBER",
"TOTALACTUALCOST",
"TOTALACTUALCOST_BASE",
"TOTALCAMPAIGNACTIVITYACTUALCOST",
"TOTALCAMPAIGNACTIVITYACTUALCOST_BASE",
"TRANSACTIONCURRENCYID",
"TRANSACTIONCURRENCYIDNAME",
"TRAVERSEDPATH",
"TYPECODE",
"UTCCONVERSIONTIMEZONECODE"
] %}
{% set summarize = true %}

{% set a_query %}      
    SELECT * FROM STG.ST_D365_CAMPAIGN
    QUALIFY ROW_NUMBER() OVER(PARTITION BY CAMPAIGNID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1    
{% endset %}


{% set b_query %}
    SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDCAMPAIGN
    QUALIFY ROW_NUMBER() OVER(PARTITION BY CAMPAIGNID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="CAMPAIGNID",
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

