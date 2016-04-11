% Spherical joint (3-DOF) using the XYZ-Euler representation
%
% Author        : Darwin LAU
% Created       : 2012
% Description   :
classdef SphericalEulerXYZ < Joint
        
    properties (Constant = true)
        numDofs = 3;
        numVars = 3;
        q_default = [0; 0; 0];
        q_dot_default = [0; 0; 0];
        q_ddot_default = [0; 0; 0];
        q_lb = [-pi; -pi; -pi];
        q_ub = [pi; pi; pi];
    end
    
    properties (Dependent)
        alpha
        beta
        gamma
        alpha_dot
        beta_dot
        gamma_dot
    end
    
    methods
        function value = get.alpha(obj)
            value = obj.GetAlpha(obj.q);
        end
        function value = get.alpha_dot(obj)
            value = obj.GetAlpha(obj.q_dot);
        end
        function value = get.beta(obj)
            value = obj.GetBeta(obj.q);
        end
        function value = get.beta_dot(obj)
            value = obj.GetBeta(obj.q_dot);
        end
        function value = get.gamma(obj)
            value = obj.GetGamma(obj.q);
        end
        function value = get.gamma_dot(obj)
            value = obj.GetGamma(obj.q_dot);
        end
    end
    
    methods (Static)
        function R_pe = RelRotationMatrix(q)
            alpha = SphericalEulerXYZ.GetAlpha(q);
            beta = SphericalEulerXYZ.GetBeta(q);
            gamma = SphericalEulerXYZ.GetGamma(q);
            R_01 = RevoluteX.RelRotationMatrix(alpha);
            R_12 = RevoluteY.RelRotationMatrix(beta);
            R_23 = RevoluteZ.RelRotationMatrix(gamma);
            R_pe = R_01*R_12*R_23;
        end

        function r_rel = RelTranslationVector(~)
            r_rel = [0; 0; 0];
        end
        
        function S = RelVelocityMatrix(q)
            b = SphericalEulerXYZ.GetBeta(q);
            g = SphericalEulerXYZ.GetGamma(q);
            S = [zeros(3,3); cos(b)*cos(g) sin(g) 0; -cos(b)*sin(g) cos(g) 0; sin(b) 0 1];    
        end
        
        function S_grad = RelVelocityMatrixGradient(q)
            b               =   SphericalFixedXYZ.GetBeta(q);
            g               =   SphericalEulerXYZ.GetGamma(q);
            S_grad          =   MatrixOperations.Initialise([6,3,3],isa(q, 'sym'));
            S_grad(:,:,2)   =   [zeros(3,3);-sin(b)*cos(g),0,0;sin(b)*sin(g),0,0;cos(b),0,0];
            S_grad(:,:,3)   =   [zeros(3,3);-cos(b)*sin(g),cos(g),0;-cos(b)*cos(g),-sin(g),0;0,0,0];
        end
        
%         function S_dot = RelVelocityMatrixDeriv(q, q_dot)
%             b = SphericalEulerXYZ.GetBeta(q);
%             g = SphericalEulerXYZ.GetGamma(q);
%             b_d = SphericalEulerXYZ.GetBeta(q_dot);
%             g_d = SphericalEulerXYZ.GetGamma(q_dot);
%             S_dot = [zeros(3,3); -b_d*sin(b)*cos(g)-g_d*cos(b)*sin(g) g_d*cos(g) 0; ...
%                 b_d*sin(b)*sin(g)-g_d*cos(b)*cos(g) -g_d*sin(g) 0; ...
%                 b_d*cos(b) 0 0];
%         end
        
        function [N_j,A] = QuadMatrix(q)
            b = SphericalEulerXYZ.GetBeta(q);
            g = SphericalEulerXYZ.GetGamma(q);
            N_j = [0,-0.5*sin(b)*cos(g),-0.5*cos(b)*sin(g),0,0.5*sin(b)*sin(g),-0.5*cos(b)*cos(g),0,0.5*cos(b),0;...
                -0.5*sin(b)*cos(g),0,0.5*cos(g),0.5*sin(b)*sin(g),0,-0.5*sin(g),0.5*cos(b),0,0;...
                -0.5*cos(b)*sin(g),0.5*cos(g),0,-0.5*cos(b)*cos(g),-0.5*sin(g),0,0,0,0];
            A = [zeros(3);eye(3)];
        end
        
        function [q, q_dot, q_ddot] = GenerateTrajectory(q_s, ~, ~, q_e, ~, ~, total_time, time_step)       
            time = 0:time_step:total_time;
            quat_s = Quaternion.FromRotationMatrix(SphericalEulerXYZ.RelRotationMatrix(q_s));
            quat_e = Quaternion.FromRotationMatrix(SphericalEulerXYZ.RelRotationMatrix(q_e));
            
            % Rotation matrix for q_s
            R_0s = SphericalEulerXYZ.RelRotationMatrix(q_s);
            
            [quat, quat_dot, quat_ddot] = Quaternion.GenerateInterpolation(quat_s, quat_e, time);
            
            q = zeros(3, length(time));
            q_dot = zeros(3, length(time));
            q_ddot = zeros(3, length(time));
            
            for t = 1:length(time)
                R_sp = Quaternion.ToRotationMatrix(quat(t));
                % Rotation matrix and its derivatives for q at this instance in time
                R_0p = R_0s*R_sp;
                R_sp_dot = Quaternion.ToRotationMatrixDeriv(quat(t), quat_dot(t));
                R_0p_dot = R_0s*R_sp_dot;
                R_sp_ddot = Quaternion.ToRotationMatrixDoubleDeriv(quat(t), quat_dot(t), quat_ddot(t));
                R_0p_ddot = R_0s*R_sp_ddot;
                
                [a, b, g] = SphericalEulerXYZ.RotationMatrixToEulerAngles(R_0p);
                
                [a_d, b_d, g_d] = SphericalEulerXYZ.RotationMatrixToEulerAnglesDeriv(a, b, g, R_0p_dot);                
                if (~isfinite(a_d))
                    if (t>1)
                        a_d = (a-q(1,t-1))/(time(t)-time(t-1));
                    else
                        a_d = 0;
                    end
                end
                if (~isfinite(b_d))
                    if (t>1)
                        b_d = (b-q(2,t-1))/(time(t)-time(t-1));
                    else
                        b_d = 0;
                    end
                end
                if (~isfinite(g_d))
                    if (t>1)
                        g_d = (g-q(3,t-1))/(time(t)-time(t-1));
                    else
                        g_d = 0;
                    end
                end
                
                [a_dd, b_dd, g_dd] = SphericalEulerXYZ.RotationMatrixToEulerAnglesDerivD(a, b, g, a_d, b_d, g_d, R_0p_ddot);
                if (~isfinite(a_dd))
                    if (t>1)
                        a_dd = (a_d-q_dot(1,t-1))/(time(t)-time(t-1));
                    else
                        a_dd = 0;
                    end
                end
                if (~isfinite(b_dd))
                    if (t>1)
                        b_dd = (b_d-q_dot(2,t-1))/(time(t)-time(t-1));
                    else
                        b_dd = 0;
                    end
                end
                if (~isfinite(g_dd))
                    if (t>1)
                        g_dd = (g_d-q_dot(3,t-1))/(time(t)-time(t-1));
                    else
                        g_dd = 0;
                    end
                end
                
                q(1,t) = a;
                q(2,t) = b;
                q(3,t) = g;
                q_dot(1,t) = a_d;
                q_dot(2,t) = b_d;
                q_dot(3,t) = g_d;
                q_ddot(1,t) = a_dd;
                q_ddot(2,t) = b_dd;
                q_ddot(3,t) = g_dd;
            end
        end
        
        % Get variables from the gen coordinates
        function alpha = GetAlpha(q)
            alpha = q(1);
        end
        function beta = GetBeta(q)
            beta = q(2);
        end
        function gamma = GetGamma(q)
            gamma = q(3);
        end
        
        function [a, b, g] = RotationMatrixToEulerAngles(R_0p)
            % Extract the angles from the rotation matrix
            b = asin(R_0p(1,3));
            g = -atan2(R_0p(1,2), R_0p(1,1));
            a = -atan2(R_0p(2,3), R_0p(3,3));
            a = roundn(a, -10);
            b = roundn(b, -10);
            g = roundn(g, -10);
        end
        
        function [a_d, b_d, g_d] = RotationMatrixToEulerAnglesDeriv(a, b, g, R_0p_dot)
            b_d = R_0p_dot(1,3)/cos(b);
            g_d = (-b_d*sin(b)*cos(g)-R_0p_dot(1,1))/(cos(b)*sin(g));
            a_d = (-b_d*cos(a)*sin(b)-R_0p_dot(3,3))/(sin(a)*cos(b));
            a_d = roundn(a_d, -10);
            b_d = roundn(b_d, -10);
            g_d = roundn(g_d, -10);
        end
        
        function [a_dd, b_dd, g_dd] = RotationMatrixToEulerAnglesDerivD(a, b, g, a_d, b_d, g_d, R_0p_ddot)
            b_dd = (R_0p_ddot(1,3)+b_d^2*sin(b))/cos(b);
            g_dd = (-b_dd*sin(b)*cos(g)-b_d*(b_d*cos(b)*cos(g)-g_d*sin(b)*sin(g))-g_d*(-b_d*sin(b)*sin(g)+g_d*cos(b)*cos(g))-R_0p_ddot(1,1))/(cos(b)*sin(g));
            a_dd = (-a_d*(a_d*cos(a)*cos(b)-b_d*sin(a)*sin(b))-b_dd*cos(a)*sin(b)-b_d*(-a_d*sin(a)*sin(b)+b_d*cos(a)*cos(b))-R_0p_ddot(3,3))/(sin(a)*cos(b));
            a_dd = roundn(a_dd, -10);
            b_dd = roundn(b_dd, -10);
            g_dd = roundn(g_dd, -10);
        end
    end
end

