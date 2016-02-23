% An approximation of the dexterity measure which applies to 
% systems subject to unilateral constraints.
%
% Please cite the following paper when using this algorithm:
% R. Kurtz and V. Hayward, "Dexterity measures with unilateral actuation 
% constraints: the n+ 1 case", Advanced Robotics, vol. 9, no. 5, pp.
% 561-577, 1994.
%
% This method has been modified to consider arbitrary cable numbers.
%
% Author        : Jonathan EDEN
% Created       : 2016
% Description   : 
classdef UnilateralDexterityMetric < WorkspaceMetricBase
    properties (SetAccess = protected, GetAccess = protected)
    end
    
    methods
        %% Constructor
        function m = UnilateralDexterityMetric()
        end
        
        %% Evaluate Functions
        function v = evaluate(obj,dynamics,options,method,inWorkspace)
            if((nargin <=3)||(~(method==StaticMethods.UD)))
                if(nargin == 2)
                    options = optimset('Display','off');
                end
                % Determine the Jacobian Matrix
                L = dynamics.L;
                % Compute singular values of jacobian matrix
                Sigma = svd(-L');
                % Compute the condition number
                k = max(Sigma)/min(Sigma);
                % For the moment calculate the UD assuming that all cables are
                % used
                [u,~,exit_flag] = linprog(ones(1,dynamics.numCables),[],[],-L',zeros(dynamics.numDofs,1),1e-6*ones(dynamics.numCables,1),1e6*ones(dynamics.numCables,1),[],options);
                if((exit_flag == 1) && (rank(L) == dynamics.numDofs))
                    % ADD A LATER FLAG THAT CAN USE WCW IF ALREADY TESTED
                    h = u/norm(u);
                    h_min = min(h);
                    v = sqrt(dynamics.numCables+1)*(1/k)*(h_min/sqrt(h_min^2+1));
                    % Now check if a cable is not necessary (this is only one
                    % cable for now future work will look at combinatorics)
                    for i=1:dynamics.numCables
                        W = eye(dynamics.numCables);
                        W(i,:) = [];
                        % Determine necessary variables for test
                        L_m       =   W*L; % Cable Jacobian
                        L_rank  =   rank(L');   % Cable Jacobian Rank
                        % Test if Jacobian has a positive spanning subspace
                        f       =   ones(dynamics.numCables-1,1);
                        Aeq     =   -L_m';
                        lb      =   1e-6*ones(dynamics.numCables-1,1);
                        ub      =   Inf*ones(dynamics.numCables-1,1);
                        [u,~,exit_flag] = linprog(f,[],[],Aeq,zeros(dynamics.numDofs,1),lb,ub,[],options);
                        % Test if the Jacobian is full rank
                        if((exit_flag==1) && (L_rank == dynamics.numDofs))
                            h = u/norm(u);
                            Sigma = svd(-L_m');
                            k = max(Sigma)/min(Sigma);
                            h_min = min(h);
                            temp_v = sqrt(dynamics.numCables)*(1/k)*(h_min/(sqrt(h_min^2+1)));
                            if(temp_v > v)
                                v = temp_v;
                            end
                        end
                    end
                else
                    v = 0;
                end
            else
                v = inWorkspace;
            end
        end
    end
end