%---------------------------------------------------------------%
%   UCSD DBF Propulsions Subteam 
%   Propeller & Motor Data Import Script
%   
%   Data sheets MUST be converted to an .XLSX file from the .txt
%   file generated off of the APC website
%   https://www.apcprop.com/technical-information/performance-data/
%   Using Excel, open the .txt file, use Delimited, check Spaces, 
%   and do not import column (skip first column). Then save
%   as a .xlsx file in the same directory that this script is in
%   
%   Errors may occur when importing new Propeller data sheets. This occurs 
%   because the APC datasheets //suck// sometimes import '-Nan' values 
%   into the cells. Simply replace the Nan values with zeros. They 
%   usually occur at high RPM values and are <10 of them, so it can be 
%   considered negligible.
%
%   Electric Motor Data only requires Kv, No-Load Current,
%   and Motor Resistance (Kv,I0,Rm respectively). Information is usually
%   found on the purchase website. Scorpion Motors are pretty good :)
%   https://www.scorpionsystem.com/catalog/aeroplane/motors_1/
%
%   First Created by 
%   Ryan Dunn 
%   Propulsions Lead 2019-2021
%   
%   Last Editted by
%   Kevin Vo
%   Propulsions Lead 2021
%   1/10/2021

%% Variable Legend
% -------------- Input Variables --------------

% MotorFile = An input variable containing the imported Motor excel sheet, 
% which contains: NAME, Kv, Rm, and I_0 of various motors.

% PropFiles = An input variable containing all the imported Propeller Data
% sheets. Each propeller data sheet contains V, J, Pe, Ct, PWR, Torque, 
% and Thrust of each propeller type.

% -------------- Output Variables in DataImport.mat --------------

% Motornames = contains the names of motors
% Kv = ratio of the motor's unloaded rpm to the peak voltage on the wires
% connected  to the coils [RPM/Volt] This rating is helpful to determine
% how fast a motor will rotate when a given voltage is applied to it.
% I0 = No-Load Current @ 10 Volts: The no-load current is the current 
% required just to turn the motor shaft with nothing connected. [Amps]
% Rm = Motor Resistance [Ohms]

% Propnames = name of propeller ([propeller diameter, pitch])
% diameter = propeller diameter [in]
% pitch = propeller pitch [in]
% maxRPM = maximum RPM of propeller
% V = model speed [mph]
% J = advance ratio (J=V/nD)
% Pe = propeller efficiency
% Ct = thrust coefficient (Ct=T/(rho * n**2 * D**4))
% Cp = power coefficient (Cp=P/(rho * n**3 * D**5))
% PWR = power [Hp]
% Qprop = propeller torque [In-lbf]
% T = thrust [lbf]

%% Initialize
clear all; close all; format longg; clc;
%% Input Sheets
MotorFile = 'Motor_data.xlsx';
PropFiles  = {'6x4E.xlsx'
            '7x4E.xlsx'
            '8x6E.xlsx'
            '8x8E.xlsx'
            '9x6.xlsx'
            '9x6E.xlsx'
            '10x5E.xlsx'
            '10x6.xlsx'
            '10x6E.xlsx'
            '10x7.xlsx'
            '10x7E.xlsx'
            '10x8E.xlsx'
            '10x9.xlsx'
            '10x10.xlsx'
            '10x10E.xlsx'
            '11x5.xlsx'
            '11x55E.xlsx'
            '11x6.xlsx'
            '11x7.xlsx'
            '11x7E.xlsx'
            '11x8E.xlsx'
            '11x9.xlsx'
            '11x10E.xlsx'
            '11x11.xlsx'
            '11x12E.xlsx'
            '12x8.xlsx'
            '12x8E.xlsx'
            '12x10E.xlsx'
            '13x4.xlsx'
            '13x65E.xlsx'
            '13x7.xlsx'
            '13x8.xlsx'
            '13x9.xlsx'
            '13x8E.xlsx'
            '13x10E.xlsx'
            '13x11.xlsx'
            '14x7.xlsx'
            '14x7E.xlsx'
            '14x85E.xlsx'
            '14x10E.xlsx'
            '15x8.xlsx'};

%% Initialize & Import

% Import Propellers Loop
for FILE=1:length(PropFiles)
    % Open File
    insheet = readcell(PropFiles{FILE},'Sheet',1);
    Propnames{FILE} = insheet{1,1};
    diameter(FILE)  = str2num(Propnames{FILE}(1:(find(Propnames{FILE}=='x')-1)));
    pitch{FILE}     = Propnames{FILE}(((find(Propnames{FILE}=='x')+1):end));
    maxRPM(FILE)    = (size(insheet,1)-10)/37;
    % Import chunks of data based on RPM
    for i=1:maxRPM(FILE)
       % Direct Import
       V{FILE}{i}       = cell2mat(insheet((-19+37*i):(10+37*i),1));
       J{FILE}{i}       = cell2mat(insheet((-19+37*i):(10+37*i),2));
       Pe{FILE}{i}      = cell2mat(insheet((-19+37*i):(10+37*i),3));
       Ct{FILE}{i}      = cell2mat(insheet((-19+37*i):(10+37*i),4));
       Cp{FILE}{i}      = cell2mat(insheet((-19+37*i):(10+37*i),5));
       PWR{FILE}{i}     = cell2mat(insheet((-19+37*i):(10+37*i),6));
       Qprop{FILE}{i}   = cell2mat(insheet((-19+37*i):(10+37*i),7));
       T{FILE}{i}       = cell2mat(insheet((-19+37*i):(10+37*i),8));
    end
    fprintf('imported propeller #%d successfully\n',FILE)
end
fprintf('imported propellers successfully\n',length(PropFiles));

% Read Motor File
insheet = readcell(MotorFile,'Sheet',1);
for i=1:(size(insheet,1)-1)
    Motornames{i} = insheet{i+1,1};    
    Kv(i) = insheet{i+1,2};
    Rm(i) = insheet{i+1,3};
    I0(i) = insheet{i+1,4};
end
fprintf('imported motors successfully\n');

%clear FILE temp i PropFiles MotorFile insheet
clear FILE temp i MotorFile insheet

save('DataImport.mat')
fprintf('done\n')