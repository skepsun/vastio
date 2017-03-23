######################     run model and evaluate p  ##############################
run_model <- function(in_data_site,in_data_name,model_site,out_data_model_name){
##�����Ѳ�ֵ������ļ�
	load(paste(in_data_site,in_data_name,".RData",sep=""),.GlobalEnv)
##���в�ͬģ��
	####ȫ����ģ��
	logit <- glm(crime_bi~.-date_str-grid_num-crime_num,data=train_data,family=binomial(link="logit"))

	####stepɸѡ����ģ��
	logit_step <- step(logit,trace=0)

	####�ɵ�stepɸѡ����ģ��
	p_frame <- as.matrix(summary(logit)$coef)
	#drop_var <- names(which(p_frame[,4]>=alpha))
	drop_var <- names(which(p_frame[,4]>=0.1))
	drop_col_index <- which(names(train_data) %in% drop_var)
	if(length(drop_var)==0) fmla <- as.formula(paste("crime_bi ~ ",paste(names(train_data[,-c(1:4)]),collapse= "+")))
	if(length(drop_var)>=1) fmla <- as.formula(paste("crime_bi ~ ",paste(names(train_data[,-c(1:4,drop_col_index)]),collapse= "+")))
	logit_nostep <- glm(fmla,data=train_data,family=binomial(link="logit"))

	#### ����ģ�� ####
	#
	# ����� 
	#
	##################


	train_data <- train_data[,1:4]
	gc(reset=TRUE)

save(train_data,test_data,logit,logit_step,logit_nostep,other_model,,,,file=paste(model_site,out_data_model_name,".RData",sep=""))

rm(list=ls())
gc(reset=TRUE)
}


cat("#####�ѳɹ�����ģ�ͺ���#####
#####�ɴ���Ĳ���˵�������ú���run_model(in_data_site,in_data_name,model_site,out_data_model_name
  in_data_site:          ���뻮�ֺõ����ݼ����ڵ��ļ�·��,�磺'c:\\xx\\xxx'  ��  'c:/xx/xxx' 
  in_data_name:          ���뻮�ֺõ����ݼ���R�ļ���,�磺'207_train_test_data'
  model_site:            �������ݺ�ģ�͵��ļ�·��,��ʽͬin_data_site
  out_data_model_name:   �������ݺ�ģ�͵��ļ���,�磺'207_data_model' 
############################################################",sep="\n")   


run_model(in_data_site,in_data_name,model_site,out_data_model_name)


