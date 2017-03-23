#Base-Probility-PPS

baseP_stat <- function(file_site,file_name,len_day=NULL,len_day_cut=NULL,out_data_p_site,out_data_p_name){
	
	####����,������ֹ��ʾ��################
        if(is.character(file_site)==F | is.character(file_name)==F | is.character(out_data_p_site)==F | is.character(out_data_p_name)==F) 
	   stop("ERROR:file_site,file_name,out_data_p_site,out_data_p_name must be a character")
	if(is.null(len_day) & is.null(len_day_cut)) stop("ERROR:please make sure one of the arguments(len_day,len_day_cut) is not null")

	#######################################

	##��������,���ݸ�ʽ��[.txt],.csv,�ޱ�ͷ(�ֶΡ�������)------����ʹ��ʱ���޸�
	crime_data_p <- read.table(paste(file_site,file_name,".csv",sep=""),header=T,sep=",")

	# names(crime_data_p)=c('date_str', 'grid_num', 'crime_num', 'crime_bi', 'same_crime', 'human_trace', 'bank', 'temporal_spatial_0_0', 
	#          'temporal_spatial_0_1', 'temporal_spatial_1_0', 'temporal_spatial_1_1', 'temporal_spatial_2_0', 'temporal_spatial_2_1',
	#          'temporal_spatial_3_0', 'temporal_spatial_3_1', 'temporal_spatial_4_0', 'temporal_spatial_4_1')
	###########	
		    
	crime_data_p <- crime_data_p[,1:4]
	gc(reset=T)

	crime_data_p$date_str <- as.Date(as.character(crime_data_p$date_str),"%Y%m%d")
	crime_data_p <- crime_data_p[order(crime_data_p$date_str,crime_data_p$grid_num),]

	##������ʱ,����
	(min_date=min(crime_data_p$date_str));(max_date=max(crime_data_p$date_str))
	(day_count=length(crime_data_p[!duplicated(crime_data_p$date_str),"date_str"]))
	##��������
	grid_list=crime_data_p[!duplicated(crime_data_p$grid_num),"grid_num"]
		(grid_count=length(grid_list))
	    
	##���㲻ͬ�����Ļ�������,������ϵ������len_day,�ֶ�����len_day_cut

	##��ǰ��len��ķ����İ�����/len����
	stat_len <- function(x,len){
	    x[,(ncol(x)+1):(ncol(x)+length(len))] <-NA
	    ##������ϵ
	    #if(TorF==FALSE) names(x)[(ncol(x)-length(len)+1):ncol(x)] <-paste("len_day_",len,sep="")
	    ##�ֶι�ϵ
	    #if(TorF==TRUE) names(x)[(ncol(x)-length(len)+1):ncol(x)] <-paste("len_day_cut_",len,sep="")
	    
	    #rownames(x) <- 1:day_count
	    for(j in len){
		for(i in (day_count:(j+1))){
		    x[i,which(len==j)+ncol(x)-length(len)] <- sum(x[((i-1):(i-j)),"crime_bi"])       
		}
	    }
	    return(x)
	}

	##������ϵ
	if(is.null(len_day)==F & is.null(len_day_cut)==T){
	    stat_len_day <- as.function(alist(x=,len=len_day,stat_len(x,len)))
	    library(plyr)
	    crime_data_p <- ddply(crime_data_p,.(grid_num=as.factor(grid_num)),stat_len_day)
	    crime_data_p[,(ncol(crime_data_p)-length(len_day)+1):ncol(crime_data_p)] <- t(t(crime_data_p[,(ncol(crime_data_p)-length(len_day)+1):ncol(crime_data_p)])/len_day)
	    names(crime_data_p)[(ncol(crime_data_p)-length(len_day)+1):ncol(crime_data_p)] <-paste("len_day_p",len_day,sep="")    
	}

	##�ֶι�ϵ
	if(is.null(len_day)==T & is.null(len_day_cut)==F){
	    stat_len_cut <- as.function(alist(x=,len=cumsum(len_day_cut),stat_len(x,len)))
	    library(plyr)
	    crime_data_p <- ddply(crime_data_p,.(grid_num=as.factor(grid_num)),stat_len_cut)
	    if(length(len_day_cut)==1){
	        crime_data_p[,ncol(crime_data_p)] <- crime_data_p[,5]/len_day_cut
		names(crime_data_p)[ncol(crime_data_p)] <-  paste("len_day_cut_p",len_day_cut,sep="")
	    }
	    if(length(len_day_cut)>1){
	        for(i in (length(len_day_cut)-1)){
		    crime_data_p[,i+ncol(crime_data_p)-length(len_day_cut)+1] <- crime_data_p[,i+ncol(crime_data_p)-length(len_day_cut)+1]-crime_data_p[,i+ncol(crime_data_p)-length(len_day_cut)]            
	        }
	        crime_data_p[,(ncol(crime_data_p)-length(len_day_cut)+1):ncol(crime_data_p)] <- t(t(crime_data_p[,(ncol(crime_data_p)-length(len_day_cut)+1):ncol(crime_data_p)])/len_day_cut)
	        names(crime_data_p)[(ncol(crime_data_p)-length(len_day_cut)+1):ncol(crime_data_p)] <-paste("len_day_cut_p",len_day_cut,sep="")
	    }
	}

	##����+�ֶι�ϵ
	if(is.null(len_day)==F & is.null(len_day_cut)==F){
	    stat_len_day <- as.function(alist(x=,len=len_day,stat_len(x,len)))
	    library(plyr)    
	    crime_data_p <- ddply(crime_data_p,.(grid_num=as.factor(grid_num)),stat_len_day)
	    crime_data_p[,(ncol(crime_data_p)-length(len_day)+1):ncol(crime_data_p)] <- t(t(crime_data_p[,(ncol(crime_data_p)-length(len_day)+1):ncol(crime_data_p)])/len_day)
	    names(crime_data_p)[(ncol(crime_data_p)-length(len_day)+1):ncol(crime_data_p)] <-paste("len_day_p",len_day,sep="") 

	    stat_len_cut <- as.function(alist(x=,len=cumsum(len_day_cut),stat_len(x,len)))
	    crime_data_p <- ddply(crime_data_p,.(grid_num=as.factor(grid_num)),stat_len_cut)
	    if(length(len_day_cut)==1){
	        crime_data_p[,ncol(crime_data_p)] <- crime_data_p[,5]/len_day_cut
		names(crime_data_p)[ncol(crime_data_p)] <-  paste("len_day_cut_p",len_day_cut,sep="")
	    }
	    if(length(len_day_cut)>1){
	        for(i in (length(len_day_cut)-1)){
		    crime_data_p[,i+ncol(crime_data_p)-length(len_day_cut)+1] <- crime_data_p[,i+ncol(crime_data_p)-length(len_day_cut)+1]-crime_data_p[,i+ncol(crime_data_p)-length(len_day_cut)]            
	        }
	        crime_data_p[,(ncol(crime_data_p)-length(len_day_cut)+1):ncol(crime_data_p)] <- t(t(crime_data_p[,(ncol(crime_data_p)-length(len_day_cut)+1):ncol(crime_data_p)])/len_day_cut)
	        names(crime_data_p)[(ncol(crime_data_p)-length(len_day_cut)+1):ncol(crime_data_p)] <-paste("len_day_cut_p",len_day_cut,sep="")
	    }
	}

save(crime_data_p,file=paste(out_data_p_site,out_data_p_name,".RData",sep=""))

	#return(crime_data_p)
rm(list=ls())
gc(reset=TRUE)
}

cat("#####�ѳɹ��������ɶ��л������ʺ���#####
#####�ɴ���Ĳ���˵�������ú���baseP_stat(file_site,file_name,len_day=NULL,len_day_cut=NULL,out_data_p_site,out_data_p_name)
  file_site:             �������ɾ������ݵ��ļ�·��,'d:/xx/xxx' �� 'd:\\xx\\xxx'(�ַ���)
  file_name:             ���ɾ������ݵ��ļ���,'xxxx'(�ַ���)----##ͳһ���ݸ�ʽΪ.csv
  len_day:               �����������ʱ������ǰ��������,�ɴ�������,��c(1,2,3)----������ϵ
  len_day_cut:           �����������ʱ�����ǰ��������,�ɴ�������------------�ֶι�ϵ
                         ##len_day,len_day_cut���߲���ͬʱΪ��,��ͬʱ�ǿ�
  out_data_p_site:       ��������������ʵ������ļ���·��ֵ,��ʽͬfile_site
  out_data_p_name��      ��������������ʵ������ļ���,��ʽͬfile_name
############################################################",sep="\n")   
    
##  crime_data_p <- baseP_stat(file_site="q:/",file_name="mudu_class1",len_day=NULL,len_day_cut=c(30,60),out_data_p_site="q:/",out_data_p_name="xxxxxxxxx")
    

