%This is a main file to test the new wrench set approximations.

%% Setup
% Load configs
clc; clear; warning off; close all;
%% Set up folders
% Change this
% Darwin's Computer
% folder = 'D:\Darwin''s Notebook Documents\Work\Research\Studies\Cable-driven manipulators\Simulations\Kinematics_dynamics';

% Jonathan's Home computer
% folder = 'C:\Users\Eden\Dropbox\mcdm-analysis.matlab';
% addpath(genpath('C:\Users\Eden\Dropbox\mcdm-analysis.matlab'));

% Jonathan's Laptop
% addpath(genpath('/home/jonathan/Dropbox/mcdm-analysis.matlab'))
% folder = '/home/jonathan/Dropbox/mcdm-analysis.matlab';

% Jonathan's Uni Computer
addpath(genpath('C:\Users\jpeden\Dropbox\mcdm-analysis.matlab'))
folder = 'C:\Users\jpeden\Dropbox\mcdm-analysis.matlab';
subfolder = 'systems_prop';

if(isunix)
    dlm = '/';
else
    dlm = '\';
end

% 2R Model - 4 Cables
model_folder        =   '2R_model';
cable_file          =   '2R_ideal_cable_props.csv';
body_file           =   '2R_body_prop.csv';

% model_folder        =   '2R_model_3C';
% cable_file          =   '2R_ideal_cable_props.csv';
% body_file           =   '2R_body_prop.csv';

% Files
cables_prop_filepath = [folder,dlm,subfolder,dlm,model_folder,dlm,cable_file];
bodies_prop_filepath = [folder,dlm,subfolder,dlm,model_folder,dlm,body_file];

% Constructor for bodies and cables
bkConstructor = @() SystemKinematicsBodiesRigid(bodies_prop_filepath);
ckConstructor = @() SystemKinematicsCablesIdeal(cables_prop_filepath);
bdConstructor = @() SystemDynamicsBodiesRigid(bodies_prop_filepath);
cdConstructor = @() SystemDynamicsCablesIdeal(cables_prop_filepath);
% add SystemKinematicsTask, SystemDynamicsTask
% Construct the kinematics
sdConstructor = @() SystemDynamics(bdConstructor, cdConstructor, bkConstructor, ckConstructor);

%% Setup the simulation
disp('Start Setup Simulation');
start_tic       =   tic;
% The pose to generate wrench set for
q2 = -pi/6;
q = [pi/6;q2];
time_elapsed    =   toc(start_tic);
fprintf('End Setup Simulation : %f seconds\n', time_elapsed);

%% Start the simulation
disp('Start Running Simulation');
start_tic       =   tic;
dynamics = sdConstructor();
dynamics.update(q, zeros(size(q)), zeros(size(q)));
w = WrenchSet(dynamics.L,dynamics.cableDynamics.forcesMax,dynamics.cableDynamics.forcesMin);
w_ca = w.sphereApproximationCapacity(dynamics.G);
w_ch = w.sphereApproximationChebyshev();
w_sp = w.sphereApproximationMax(dynamics.G,0);
time_elapsed    =   toc(start_tic);
fprintf('End Running Simulation : %f seconds\n', time_elapsed);
% m = UnilateralDexterityMetric();
% m = TensionFactorMetric();
m = CapacityMarginMetric();
% m = RelativeVolumeMetric();
% m = RelativeRadiusMetric([0;0])
% m = SemiSingularMetric()
mv = m.evaluate(dynamics);
mv
%% Plot the wrench sets
disp('Start Plotting Simulation');
start_tic = tic;
figure; hold on; grid on;
for i = 1:w.n_faces
    x = [-3000,3000];
    y = (1/w.A(i,2)).*(w.b(i) - w.A(i,1)*x);
    plot(x,y,'b')
end
axis([-3000,3000,-3000,3000])
% Plot the capacity margin approximation
theta = -pi:pi/100:pi;
x1 = w_ca.T(1) + w_ca.r*cos(theta);x2 = w_ca.T(2) + w_ca.r*sin(theta);
plot(x1,x2,'m')
% Plot the Chebyshev sphere
theta = -pi:pi/100:pi;
x1 = w_ch.T(1) + w_ch.r*cos(theta);x2 = w_ch.T(2) + w_ch.r*sin(theta);
plot(x1,x2,'c')
% Plot the largest sphere
theta = -pi:pi/100:pi;
x1 = w_sp.T(1) + w_sp.r*cos(theta);x2 = w_sp.T(2) + w_sp.r*sin(theta);
plot(x1,x2,'g')
time_elapsed    =   toc(start_tic);

a = 0.5*sin(q2);
rm = (mv^2/(3*a^2))^(0.25)
% for r = 0:0.5:rm
%     for theta = -pi:pi/10:pi
%         qd1 = r*cos(theta);
%         qd2 = r*sin(theta);
%         dynamics.update(q, [qd1;qd2], zeros(size(q)));
%         x = dynamics.G + dynamics.C;
%         plot(x(1),x(2),'rx')
%     end
%     pause(0.5);
% end

% Add a measure of the distance to the boundary of the vector that the
% intersection occurs for.
if(mv>0)
    qe   =   w.n_faces;
    s   =   zeros(qe,1);
    t = sign(sin(q(2)));
    for j=1:qe
        s(j) = (w.b(j) - w.A(j,:)*dynamics.G)/norm(w.A(j,:));
        % Find the point of intersection
        p = dynamics.G + s(j)*(w.A(j,:)')/norm(w.A(j,:))
        s(j)
        % Check if the point of intersection is not in the correct half space
        if(t*(p(2)-dynamics.G(2))<0)
            pd = (1/w.A(j,1))*(w.b(j) - w.A(j,2)*dynamics.G(2))
            if(abs(pd)==Inf)
                s(j) = Inf;
            else
                s(j) = abs(pd - dynamics.G(1));
            end
            % Find the correct intersection of the boundary ray to the line
        end
    end
    v = min(s);
    rm = (v^2/(3*a^2))^(0.25)
    
    % Plot the capacity margin approximation
    theta = -pi:pi/100:pi;
    x1 = w_ca.T(1) + v*cos(theta);x2 = w_ca.T(2) + v*sin(theta);
    plot(x1,x2,'r')
end 

for r = 1
    for theta = -pi:pi/100:pi
        qd1 = r*cos(theta);
        qd2 = r*sin(theta);
        dynamics.update(q, [qd1;qd2], zeros(size(q)));
        x = dynamics.G + dynamics.C;
        plot(x(1),x(2),'rx')
    end
    pause(0.5);
end


% Add another measure for the special case which uses the known boundary