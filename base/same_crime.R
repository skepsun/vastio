##same_crime
##����ͬ�ڰ�����

case_stat_same_crime <- function(id,start_date,gd_size,ahead,aback,out_data_site,out_data_name){
#�趨[ȫ��]��Ч����λ��
options(digits=10)

#�����������ݿ�ļ��ذ���DBI,ROracle
library(DBI)
library(ROracle)

#�����ݿ����������
drv <- dbDriver("Oracle")

#����oracle���ݿ�,username="szgadba",password="Peptalk123"
#host <- "10.15.100.104"
#port <- 1521
#svc <- "orcl"
#connect.string <- paste(
#"(DESCRIPTION=",
#"(ADDRESS=(PROTOCOL=tcp)(HOST=", host, ")(PORT=", port, "))",
#"(CONNECT_DATA=(SERVICE_NAME=", svc, ")))", sep = "")

con <- dbConnect(drv,"szgadba","Peptalk123"
                 #  ,dbname = "P77"
                 )
        #####dr <- dbReadTable(con, "PPS_CRIME_DATA")
        #####head(dr)###ֱ�Ӳ鿴���ݱ�PPS_CRIME_DATA

    #print(ls())###R�Զ��庯���Ĳ�������ǰ���뵽���㻷����

    if(is.numeric(id)==FALSE) stop("ERROR:please make sure id is numeric")
    if(is.numeric(start_date)==FALSE | nchar(start_date)!=8) stop("ERROR:please make sure start_date like 20140101")
    if(is.numeric(gd_size)==FALSE | length(gd_size)!=1 | (gd_size %in% c(50,100,150,200))==FALSE) stop("ERROR:please make sure gd_size is numeric and is in the vector(50,100,150,200)")
    if(is.numeric(ahead)==FALSE | is.numeric(aback)==FALSE) stop("ERROR:please make sure ahead and aback are nummerical")
    if(is.character(out_data_site)==F | is.character(out_data_name)==F) stop("ERROR:please make sure file_path is character")

    ###����ĳ���ɳ����İ�������,�Զ�����ʼʱ�� 
    type_id <- "(011705,011710,011712,011713,011714,011715,011716,011717,011718,011719,011790,020201,020204,020205,020206,020207,
                020210,020211,020212,020213,020290,011700,020200,011711,020208,011701,011702,011703,020202,020203,020209,011707,
		011708,011709,011706,011704,011600,011601,011602,011603,011604,011605,011606,011607,011608,011609,011610,011611,
		011612,011613,011614,011615,011616,011617,011618,011619,011620,011621,011622,011690,011900,011901,011902,011903,
		011904,011905,011906,011907,011908,011990,010801,011800,011801,011802,011808,011809,011812,011813,011814,011815,
		020300,020301,020302,020304,020305,020306,020308,020309,020310,011810,011811,020800,020890)"
    cd <- dbGetQuery(con,paste("select to_date(substr(crime_time,1,8),'yyyy-mm-dd') as crime_date,ref_id,type_id,
                              to_char(wgs84_x) wgs84_x,to_char(wgs84_y) wgs84_y from pps_crime_data where pd_id=",id,
			      "and type_id in",type_id,
			      "and to_date(substr(crime_time,1,8),'yyyy-mm-dd') >=","to_date('",start_date,"','yyyy-mm-dd')-365-30",sep=" "))

    cd$CRIME_DATE <- as.Date(as.character(cd$CRIME_DATE),"%Y-%m-%d")

    ###����ĳ���ɳ���,��ͬ���Ӵ�С�ľ�γ���������� 
    grid_data <- function(gd_size,id,char="is not null") {
         grid_size <- dbGetQuery(con, paste("select grid_num,to_char(p1_x) p1_x,to_char(p1_y) p1_y,to_char(p2_x) p2_x ,to_char(p2_y) p2_y,
                is_buffer from",paste("grid_info_",gd_size,"m_wgs84",sep=""),"where pd_id =",id,"and is_buffer",char,sep=" "))
    return(grid_size)
    }

    ###��дgrid_data����,ֻ��ȡ���������������ĸ���,Ŀ�ģ�����ƥ�����
    grid_data_0 <- as.function(alist(gd_size=,id=,char="=0",grid_data(gd_size,id,char)))
    gd0 <- grid_data_0(gd_size,id)

    #######################################################################################################
    ###������ƥ�䵽������
    ###������GRID_NUM�����ݼ�cd
    cd$GRID_NUM <- NA
    for(i in 1:nrow(cd)){
        index <- which(cd$WGS84_X[i] >= gd0$P1_X & cd$WGS84_X[i] <= gd0$P2_X &
                     cd$WGS84_Y[i] >= gd0$P2_Y & cd$WGS84_Y[i] <= gd0$P1_Y)
        if(length(index)==0) cd$GRID_NUM[i] <- NA        
        if(length(index)>=1) cd$GRID_NUM[i] <- gd0[index[1],"GRID_NUM"]
    }#sum(is.na(cd$GRID_NUM))#229������û��ƥ�䵽����---¦��20130101->20140929
 
    ###�����ڴ�
    rm(list=ls()[-which(ls() %in% c("cd","start_date","gd_size","ahead","aback","out_data_site","out_data_name"))])
    gc(reset=TRUE)

    #######################################################################################################
    ###������챾���ӵİ����� 
    stat_grid_0 <- aggregate(cd$REF_ID,list(date_str=cd$CRIME_DATE,grid_num=cd$GRID_NUM),length)
    names(stat_grid_0)[3] <- "crime_num"
    stat_grid_0$crime_bi <- ifelse(stat_grid_0$crime_num>=1,1,0)

    #######################################################################################################
    ###����same_crime
    
    stat_grid_0 <- stat_grid_0[order(stat_grid_0$date_str,stat_grid_0$grid_num),]

    seq_date <- function(x){
        temp_date <- data.frame(date_str=seq(min(cd$CRIME_DATE),max(cd$CRIME_DATE),by=1))
        temp <- merge(x[,c("date_str","crime_num","crime_bi")],temp_date,by="date_str",all=T)
        temp[is.na(temp)]<-0
	return(temp)
    }
    library(plyr)
    crime_day=ddply(stat_grid_0,.(grid_num=as.factor(grid_num)),seq_date)
    crime_day <- crime_day[order(crime_day$date_str,crime_day$grid_num),]
    rm(stat_grid_0,cd)
    gc(reset=TRUE)

    datezone <- crime_day[!duplicated(crime_day$date_str),"date_str"]


    same_ahead <- function(x,ad){
        same <- NA
	index_start <- which(datezone==as.Date(as.character(start_date),"%Y%m%d"))
	index_start_1year <- which(datezone==as.Date(as.character(start_date-10000),"%Y%m%d"))
        for(i in 0:(length(datezone)-index_start)){
	    ##������ͬ�ڵĵ���
	    same[index_start+i] <- sum(x[(index_start_1year+i-ad):(index_start_1year+i-1)])           
	}
        return(same)
    }

    same_aback <- function(x,ak){
        same <- NA
	index_start <- which(datezone==as.Date(as.character(start_date),"%Y%m%d"))
	index_start_1year <- which(datezone==as.Date(as.character(start_date-10000),"%Y%m%d"))
        for(i in 0:(length(datezone)-index_start)){
	    ##������ͬ�ڵĵ���
	    same[index_start+i] <- sum(x[(index_start_1year+i-1):(index_start_1year+i+ak)])           
	}
        return(same)
    }

    same_day <- function(x){
        same <- NA
	index_start <- which(datezone==as.Date(as.character(start_date),"%Y%m%d"))
	index_start_1year <- which(datezone==as.Date(as.character(start_date-10000),"%Y%m%d"))
        for(i in 0:(length(datezone)-index_start)){
	    ##��������ͬ�ڵĵ���
	    same[index_start+i] <- x[index_start_1year+i]
	}
	return(same)        
    }

    same_ahead  <<- as.function(alist(x=,ad=ahead,same_ahead(x,ad)))
    same_aback  <<- as.function(alist(x=,ak=aback,same_aback(x,ak)))
    same_day <<- as.function(alist(x=,same_day(x)))

     same_ahead<- ddply(crime_day,.(grid_num=grid_num),summarise,same=same_ahead(crime_num))
     names(same_ahead)[2] <- paste("same_ahead_",ahead,sep="")
     ##����R��ѭ���������
     same_ahead <- cbind(date_str=datezone,same_ahead)
 
     same_day<- ddply(crime_day,.(grid_num=grid_num),summarise,same=same_day(crime_num))
     names(same_day)[2] <- paste("same_day_",0,sep="")
     same_day <- cbind(date_str=datezone,same_day)

     same_aback<- ddply(crime_day,.(grid_num=grid_num),summarise,same=same_aback(crime_num))
     names(same_aback)[2] <- paste("same_aback_",aback,sep="")
     same_aback <- cbind(date_str=datezone,same_aback)

     ###same_ahead,same_day,same_aback��֤grid_num��˳����ͬ
     same <- cbind(same_ahead,same_day[,3],same_aback[,3])
     names(same)[4:5] <- c(paste("same_day_",0,sep=""),paste("same_aback_",aback,sep=""))
    
    rm(datezone,same_ahead,same_day,same_aback)
    gc(reset=TRUE)

    same_crime_data <- merge(crime_day,same,by=c("date_str","grid_num"))
    
    rm(crime_day)
    gc(reset=TRUE)
    
    same_crime_data <- same_crime_data[same_crime_data$date_str >= as.Date(as.character(start_date),"%Y%m%d"),]

save(same_crime_data,file=paste(out_data_site,out_data_name,".RData",sep=""))
rm(list=ls())
gc(reset=TRUE)
}

cat("#####�ѳɹ���������ͬ�ڰ���������#####
#####�ɴ���Ĳ���˵�������ú���case_stat_same_crime(id,start_date,gd_size,ahead,aback,out_data_site,out_data_name)
  id:                 �ɳ���PD_ID
  start_date:         ��Ҫ���ݾ���Ŀ�ʼʱ��
  gd_size:            ���Ӵ�С50,100,150,200
  ahead:              ͬ����ǰ���Ƶ�����
  aback               ͬ��������Ƶ�����
  out_data_site:      ���same_crime���ݵ��ļ���·����'c:\\xx\\xxx\\' �� 'c:/xx/xxx/'
  out_data_name:      ���same_crime���ݵ��ļ���
#######################################################",sep="\n") 

#case_stat_same_crime(id=207,start_date=20140101,gd_size=200,ahead=10,aback=10,out_data_site="q:/",out_data_name="xxxxxxxx")