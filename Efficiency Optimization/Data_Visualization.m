%---------------------------------------------------------------%
%   UCSD DBF Propulsions Subteam 
%   Data Visualization Script
%   
%   The general approach to this script is to visualize and
%   put as much information into a single plot as possible
%   As a result, many 3d plots, colors, and points were used
%   You must reference other scripts to find the most efficient
%   Propeller/Battery/Motor combination, then return to this file
%   to visualize its performance.
% 
%   This file requires DataImport.mat
%   
%   First Created by 
%   Ryan Dunn 
%   Propulsions Lead 2019-2021
%   
%   Last Editted by
%   Ryan Dunn
%   1/24/2021
%   
%---------------------------------------------------------------%
%   
%   ROOM FOR IMPROVEMENT:
%   
%   Re-plot figures with respect to advance ratio instead of RPM & Airspeed
%   [J = V/nD]
%   Provided Cl & Cd, find propeller's operating range by setting L=W T=D
%   Implement a Motor & Battery analysis section
%   Visualize the induced Torque by the Propeller (useful for motor selection)
%   Power Required Graph
%   
%---------------------------------------------------------------%
%% Initialize
clear all; 
% close all; 
format longg; 
clc;
%% Input Parameters

% MISSION 1 [2021 Setup]
% cp  = 18;
% cm = 11;
% Ampdraw = 16.55;
% RPMcruise = 8000;
% speed = 48.32;

% MISSION 2 [2021 Setup]
% cp  = 28;
% cm = 11;
% Ampdraw = 21.7;
% RPMcruise = 8000;
% speed = 70.69;

% MISSION 3 [2021 Setup]
cp  = 20;
cm = 11;
Ampdraw = 10.67;
RPMcruise = 8000;
speed = 54.80;

% Rated Battery Voltage (will vary throughout the flight, but assumed constant)
Voltage = 22.2;

%% Imports

% Import Propeller & Motor Datasheets
load('DataImport.mat')

% Quick Motor Efficiency Analysis (SEE STANFORD PAPER)
for Motor = 1:length(Motornames)
    Kt(Motor) = 1355/Kv(Motor);
    RPMmax(Motor) = Kv(Motor) * (Voltage - Rm(Motor)*I0(Motor));
    
    Imax{Motor} = @(RPM)(Voltage - RPM/Kv(Motor)) / Rm(Motor);
    Qmotor{Motor} = @(A) Kt(Motor)*(A-I0(Motor))*0.007061552; % in-oz to N-m [i think]
    eta_motor{Motor} = @(RPM,A) (Kt(Motor)*(A-I0(Motor))*0.007061552*RPM*2*pi/60) / (Voltage*A);
end
% Find location where cruising speed is reached
for INDEX=1:30
    if V{cp}{RPMcruise/1000}(INDEX) >= speed
        break
    end
end
eta_Prop = Pe{cp}{RPMcruise/1000}(INDEX);

%% Motor Efficiency Contours
x = @(t) t;
y = @(t) (Voltage - t/Kv(cm)) / Rm(cm);
z = @(t) (Kt(cm)*(y(t)-I0(cm))*0.007061552*t*2*pi/60) / (Voltage*y(t));

%% Static Thrust [Thrust v. Amp draw]

figure; hold on

for i = 1:maxRPM(cp)
    Qcrit = Qprop{cp}{i}(1);
    I_temp = Qcrit/(Kt(cm)*0.007061552) + I0(cm);
    if I_temp > Imax{cm}(i*1000)
        break
    end
    Ampdraw0(i) = I_temp;
    T0(i) = T{cp}{i}(1);
end
plot(Ampdraw0,T0,'b-o')

tit = sprintf('Static Thrust Capabilities for %s on %s',Propnames{cp},Motornames{cm});
title(tit)
xlabel('Amperage Draw [A]'); ylabel('Thrust [lbf]')

%% Motor [RPM v. Amp draw v. Efficiency]
for n = 1:(i-1)
    rpmplot(n) = 1000*n;
    ampplot(n) = Ampdraw0(n);
    eff(n) = eta_motor{cm}(rpmplot(n),ampplot(n));
end
figure; hold on

fplot3(x,y,z,[0 RPMmax(cm)],'k','LineWidth',2)
plot3(RPMcruise,Ampdraw,eta_motor{cm}(RPMcruise,Ampdraw),'r.','MarkerSize',35)
plot3(rpmplot,ampplot,eff,'c-o','LineWidth',5)
fsurf(eta_motor{cm},[0 RPMmax(cm) I0(cm) Imax{cm}(0)],'LineStyle',':')

legend('Line of Max Performance','Cruise Condition','Spin-up')
tit = sprintf('Motor Efficiency Surface Plot for %s',Motornames{cm});
title(tit)
xlabel('RPM'); ylabel('Amps'); zlabel('Efficiency')
axis([0 RPMmax(cm) I0(cm) Imax{cm}(0) 0 1])
view(-45,30)

%% Efficiency Contours [RPM v. Amp draw]
figure; hold on

fplot(y,[0 RPMmax(cm)],'k','LineWidth',2)
plot(RPMcruise,Ampdraw,'r.','MarkerSize',25)
fcontour(eta_motor{cm},[0 RPMmax(cm) I0(cm) Imax{cm}(0)])

axis([0 RPMmax(cm) I0(cm) Imax{cm}(0) 0 1])
legend('Line of Max Performance','Cruise Condition')
tit = sprintf('Motor Efficiency Contour Plot for %s',Motornames{cm});
title(tit)
xlabel('RPM'); ylabel('Amps')

%% Propeller [RPM v. Thrust v. Airspeed]

figure; hold on
tit = sprintf('Propeller Efficiency Curve for %s',Propnames{cp});
title(tit)
xlabel('RPM'); ylabel('Thrust [lbf]'); zlabel('Airspeed [mph]')

plot3(RPMcruise,T{cp}{RPMcruise/1000}(INDEX),speed,'r.','MarkerSize',55)

for i = 1:maxRPM(cp)
    eff(i) = max(Pe{cp}{i});
end
ideal = max(eff);
clear eff
for n=1:floor(RPMmax(cm)/1000)
    for m=1:30
        eff = Pe{cp}{n}(m);
        if eff > 0.75*ideal
            if eff == ideal
                clr = 'r.';
            elseif eff > 0.9*ideal
                clr = 'g.';
            else
                clr = 'm.';
            end
            plot3(n*1000,T{cp}{n}(m),V{cp}{n}(m),clr,'MarkerSize',20)
        else
            plot3(n*1000,T{cp}{n}(m),V{cp}{n}(m),'k.','MarkerSize',20)
        end
    end
end
legend('Cruise Condition')
view(60,15)

%% Propeller Curves [Airspeed v. Efficiency]
rpms = [1:maxRPM];

figure; hold on
tit = sprintf('%s RPM Efficiency Curves',Propnames{cp});
title(tit)
xlabel('Airspeed [MPH]'); ylabel('Efficiency')
plot(speed,eta_Prop,'r.','MarkerSize',35)
for n=1:maxRPM(cp)
    if n==RPMcruise/1000
        plot(V{cp}{n},Pe{cp}{n},'-','LineWidth',2)
    else
        plot(V{cp}{n},Pe{cp}{n},'--','LineWidth',0.5)
    end
end
legend('Cruise Condition')

%% Propeller & Motor [RPM v. Efficiency]
figure; hold on
for i=1:maxRPM(cp)
    index = find(V{cp}{i}>speed,1);
    if index
        rpmplot(i) = i*1000;
        eplot(i) = Pe{cp}{i}(index);
    end
end

plot(rpmplot,eplot,'k','LineWidth',2)
fplot(z,[0 RPMmax(cm)],'b','LineWidth',2)
plot(RPMcruise,(z(RPMcruise)*eta_Prop),'r.','MarkerSize',35)

axis([0 maxRPM(cp)*1000 0 1])
title('Efficiency Comparison of Propeller & Motor @ Cruising Speed')
xlabel('RPM'); ylabel('Efficiency'); legend('Propeller','Motor','Cruise Condition')
        
%% Print Key Values
fprintf('Static Thrust: %flbsf\nStatic AmpDraw: %fAmps\n',T0(end),Ampdraw0(end))
Propnames{cp}
Motornames{cm}

%% Just for Fun - Finding out how accurate quadratic interpolation is for Thurst vs. Velocity

% % Consider (RPM,Amps,
% figure
% hold on
% avgerr = zeros(max(maxRPM),1);
% counter = zeros(max(maxRPM),1);
% for FILE = 1:length(Propnames)
%     if FILE==25
%         continue
%     end
%     for x = 1:maxRPM(FILE)
%         coeff = polyfit(V{FILE}{x},T{FILE}{x},2);
%         bf = @(v) coeff(1)*v^2 + coeff(2)*v + coeff(3);
%         for i = 1:30
%             temp(i) = abs(diff([T{FILE}{x}(i) bf(V{FILE}{x}(i))]));
%             if T{FILE}{x}(i)==0
%                 temp(i) = 0;
%             end
%         end
%         err{FILE}(x) = 100*mean(temp)/T{FILE}{x}(1);
%         avgerr(x) = avgerr(x) + err{FILE}(x);
%         counter(x) = counter(x)+1;
%     end
% %     plot(err{FILE})
% end
% plot(avgerr./counter,'k','LineWidth',3)
% yline(mean(avgerr./counter),'k','LineWidth',3)
% mean(avgerr./counter)
% title('Quadratic Interpolation Error In Thrust(Velocity)')
% xlabel('RPM/1000')
% ylabel('% Error')

%% Min Velocity Requirements

% figure
% hold on
% title('Performance Envelope')
% xlabel('RPM')
% ylabel('Min Velocity [MPH]')
% zlabel('Thrust [lbsf]')
% view([145,35])
% for FILE=chooseprop
%     for req1 = 1:maxRPM(FILE)
%         temp = find(Qprop{FILE}{req1} < Qmotor{choosemotor}(y(req1)));
%         if isempty(temp)
%             temp = 30;
%         end
%         Vmin(req1) = V{FILE}{req1}(temp(end));
%         Tmax(req1) = T{FILE}{req1}(temp(end));
%     end
%     plot3([1000:1000:(maxRPM(FILE)*1000)],Vmin,Tmax,'LineWidth',1.5)
% end

%% Master Plot

% skiptoRPM = ceil(maxRPM/2);
% 
% figure
% hold on
% title('Master Plot')
% xlabel('Power [HP]')
% ylabel('Thrust [lbsf]')
% zlabel('Airspeed [MPH]')
% for FILE=1:length(Propnames)
%     n=skiptoRPM;
%     plot3(PWR{FILE}{n},T{FILE}{n},V{FILE}{n},colors{FILE},'LineWidth',1.2)
% end
% for FILE=1:length(PropFiles)
%     n=skiptoRPM;
%     plot3(PWR{FILE}{n}(peaksV{FILE}(n)),T{FILE}{n}(peaksV{FILE}(n)),V{FILE}{n}(peaksV{FILE}(n)),'k*')  
%     for n=skiptoRPM:maxRPM
%         if (PWR{FILE}{n}(1)>maxPWR) && (V{FILE}{n}(end)>maxV)
%             break
%         end
%         plot3(PWR{FILE}{n},T{FILE}{n},V{FILE}{n},colors{FILE},'LineWidth',1.2)
%         plot3(PWR{FILE}{n}(peaksV{FILE}(n)),T{FILE}{n}(peaksV{FILE}(n)),V{FILE}{n}(peaksV{FILE}(n)),'k*')
%     end
% end
% legend(Propnames)