bq_sql <- "
SELECT *
FROM `physionet-data.mimiciv_icu.inputevents`
WHERE itemid IN (225158, #NaCl 0.9%
            225828, #LR
            225825, #D5NS Crystalloids
            225827 #D5LR Crystalloids
)
"
bq_data <- bq_project_query(projectid, query = bq_sql)

## download results
inputevents <- bq_table_download(bq_data)

# Treatment: from folder ICU
# all.csv<-list.files(pattern = "*.csv")
# cst.list<-c(225158, #NaCl 0.9%
#             225828, #LR
#             #225944, #Sterile Water
#             #225797, #Free Water
#             #225159, #"NaCl 0.45%";"ml" -- Crystalloids
#             #225161, #"NaCl 3% (Hypertonic Saline)";"ml" -- Crystalloids
#             #225823, #"D5 1/2NS";"ml" -- Crystalloids
#             225825, #"D5NS";"ml" -- Crystalloids
#             225827 #"D5LR";"ml" -- Crystalloids
#             #225941, #"D5 1/4NS";"ml" -- Crystalloids
#             #226089 #"Piggyback";"ml" -- Crystalloids
#             )


inputevents<-inputevents%>%
  filter(hadm_id%in%cohort.id.hosp)%>%
  filter(!is.na(totalamount))


#weight
weight<-inputevents%>%
  select(hadm_id,patientweight,starttime)%>%
  group_by(hadm_id)%>%
  arrange(desc(patientweight))%>%
  filter(row_number()==1)%>%
  select(hadm_id,patientweight)

quantile(weight$patientweight,0.0025)#0.25% top
quantile(weight$patientweight,0.9975)#0.25% bottom

weight<-weight%>%filter(patientweight<229&patientweight>30)#!!!!!!!!!!!!!!

inputevents<-left_join(inputevents,cohort%>%select(stay_id,intime))
inputevents$offset<-as.numeric(difftime(inputevents$starttime,inputevents$intime,units = "min"))
inputevents$offset2<-as.numeric(difftime(inputevents$endtime,inputevents$intime,units = "min"))
inputevents<-inputevents%>%filter(amountuom%in%c("ml","L"))
inputevents$amount[inputevents$amountuom=="L"] = inputevents$amount[inputevents$amountuom=="L"]*1000
inputevents$amountuom[inputevents$amountuom=="L"] = "ml"
quantile(inputevents$totalamount,0.999,na.rm = T)#3000
quantile(inputevents$rate,0.99,na.rm = T)#750
summary(inputevents$totalamount)
hist(inputevents$totalamount)

# Imputation with Darin
inputevents<-inputevents%>%filter(ordercategoryname!="08-Antibiotics (IV)")

#bolus
bolus<-inputevents%>%
  filter(ordercategoryname=="03-IV Fluid Bolus")%>%
  filter(offset<1440&offset2<1440)
bolus$v.amount<-ifelse(bolus$totalamount>3000,3000,bolus$totalamount)


#end in the same day
non.bolus.sd<-inputevents%>%filter(ordercategoryname!="03-IV Fluid Bolus")%>%
  filter(offset2<1440)%>%
  filter(!is.na(rate))%>%
  mutate(v.amount = rate*(offset2-offset)/60)

#run between two days
non.bolus.bd<-inputevents%>%filter(ordercategoryname!="03-IV Fluid Bolus")%>%
  filter(offset<1440&offset2>1440)%>%
  filter(!is.na(rate))%>%
  mutate(v.amount = (1440-offset)*rate/60)


input.new<-rbind(non.bolus.bd,bolus,non.bolus.sd)

#
firstday.input<-input.new%>%
  filter(offset<1440&offset2<1440)%>%
  group_by(stay_id)%>%
  summarise(day1 = sum(amount))


# firstday.input<-inputevents%>%
#   filter(offset<1440&offset2<1440)%>%
#   group_by(stay_id)%>%
#   summarise(day1 = sum(amount))

quantile(firstday.input$day1,0.999)#15330
quantile(firstday.input$day1,0.001)#0.88
  #summarise(day1=sum(amount) / patientweight)
# mean(firstday.input$day1)
#cohort<-left_join(cohort,emar.fluid.total)


# sanitity check of first day input
summary(firstday.input$day1)
hist(firstday.input$day1)

#quantile(firstday.input$day1,0.99)

cohort<-left_join(cohort,firstday.input)
cohort<-left_join(cohort,weight)
nrow(cohort)#16673
cohort<-cohort%>%filter(!is.na(patientweight))

cohort$day1[is.na(cohort$day1)]=0
```

and here are library/package/hearder files needed

```
library(bigrquery)
library(tidyr)
library(DBI)
library(dbplyr)
library(dplyr)
'%!in%' <- function(x,y)!('%in%'(x,y))
