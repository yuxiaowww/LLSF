%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This is an examplar file on how the LLSF [1] program could be used.
%
% [1] J. Huang, G.-R Li, Q.-M. Huang and X.-D. Wu. Learning Label Specific Features for Multi-Label Classifcation. 
%     In: Proceedings of the International Conference on Data Mining, 2015.
% [2] J. Huang, G.-R Li, Q.-M. Huang and X.-D. Wu. Learnign label-Specific Features and Class-Dependent Labels 
%     for Multi-Label Classification, To appear in TKDE.
%
% Please feel free to contact me (huangjun.cs@gmail.com), if you have any problem about this programme.
% http://www.escience.cn/people/huangjun/index.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


warning off %#ok<WNOFF>
clear all
clc

addpath(genpath('.'));
starttime = datestr(now,0);

load 'data/genbase.mat';

%% Optimization Parameters
optmParameter.alpha   = 2^-5;  % 2.^[-10:10] % label correlation
optmParameter.beta    = 2^-3; % 2.^[-10:10] % sparsity
optmParameter.gamma   = 0.1; % {0.1, 1, 10} % initialization for W

optmParameter.searchPara = 0; % indicate whether tuning the parameters, {0:not,1:yes}
optmParameter.tuneParaOneTime = 1; % indicate that tuning the parameter one time or tuning it in each fold. {0: each fold,1: only one time}

% for large scale dataset, search ranges for alpha and beta should be set to large values,
% e.g., 4.^[-10:10];
optmParameter.alpha_searchrange = 2.^[-10:10]; 
optmParameter.beta_searchrange  = 2.^[-10:10];
optmParameter.gamma_searchrange = 10.^[-1:1];
    
optmParameter.maxIter           = 100;
optmParameter.minimumLossMargin = 0.0001;
optmParameter.bQuiet             = 1;

%% Model Parameters
modelparameter.crossvalidation    = 1; % {0,1}
modelparameter.cv_num             = 5;
modelparameter.L2Norm             = 1; % {0,1}
modelparameter.drawNumofFeatures  = 0; % {0,1}
modelparameter.deleteData         = 1; % {0,1}

%% Train and Test
if modelparameter.crossvalidation==0 
else
%% cross validation
    if exist('train_data','var')==1
        data=[train_data;test_data];
        target=[train_target,test_target];
        clear train_data test_data train_target test_target
    end
    data     = double(data);
    num_data = size(data,1);
    if modelparameter.L2Norm == 1
        temp_data = data;
        temp_data = temp_data./repmat(sqrt(sum(temp_data.^2,2)),1,size(temp_data,2));
        if sum(sum(isnan(temp_data)))>0
            temp_data = data+eps;
            temp_data = temp_data./repmat(sqrt(sum(temp_data.^2,2)),1,size(temp_data,2));
        end
    else
        temp_data = data;
    end
    if modelparameter.deleteData
        clear data
    end
    
    randorder = randperm(num_data);
    Result_LLSF  = zeros(15,modelparameter.cv_num);

    for j = 1:modelparameter.cv_num
        fprintf('Running Fold - %d/%d \n',j,modelparameter.cv_num);

       %% the training and test parts are generated by fixed spliting with the given random order
        [cv_train_data,cv_train_target,cv_test_data,cv_test_target ] = generateCVSet( temp_data,target',randorder,j,modelparameter.cv_num );
        cv_train_target=cv_train_target';
        cv_test_target=cv_test_target';

       %% Tune the parametes
        if optmParameter.searchPara == 1
            if (optmParameter.tuneParaOneTime == 1) && (exist('BestResult','var')==0)
                fprintf('\n-  parameterization for LLSF by cross validation on the training data');
                [optmParameter, BestResult ] = LLSF_adaptive_validate( cv_train_data, cv_train_target, optmParameter);
            elseif (optmParameter.tuneParaOneTime == 0)
                fprintf('\n-  parameterization for LLSF by cross validation on the training data');
                [optmParameter, BestResult ] = LLSF_adaptive_validate( cv_train_data, cv_train_target, optmParameter);
            end
        end
        
       %% If we don't search the parameters, we will run LLSF with the fixed parametrs
        [W]  = LLSF( cv_train_data, cv_train_target',optmParameter);
        Outputs       = cv_test_data*W;

       %% In our experiment, we set the threshold to be 0.5, and an appropriate threshold can be searched on the training data, and
       %% a better performance would be achieved.
        Pre_Labels  = round(Outputs');
        Pre_Labels  = (Pre_Labels >= 1);
        Pre_Labels  = double(Pre_Labels);
        
       %% evaluation of LLSF
        Result_LLSF(:,j) = EvaluationAll(Pre_Labels,Outputs',cv_test_target);

       %% count the number of label specific features for each label
        if modelparameter.drawNumofFeatures
            numofFeatures = sum(W~=0);
            figure;
            bar(numofFeatures);
        end
    end

   %% the average results of LLSF
    Avg_Result = zeros(15,6);
    Avg_Result(:,1)=mean(Result_LLSF,2);
    Avg_Result(:,2)=std(Result_LLSF,1,2);
    fprintf('\nResults of LLSF\n');
    PrintResults(Avg_Result);

end

endtime = datestr(now,0);
model_LLSF.optmParameter = optmParameter;
model_LLSF.modelparameter = modelparameter;
model_LLSF.randorder = randorder;
model_LLSF.cvResults = Result_LLSF;
model_LLSF.avgResult = Avg_Result;
model_LLSF.startTime = starttime;
model_LLSF.endTime = endtime;



