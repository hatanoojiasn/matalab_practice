%% make_model_02.m
% Build ACC MILS model with readable, extensible Simulink structure.
% Top-level structure:
%   Inputs_Scenario -> ACC_Controller -> Plant -> Monitor

thisFile = mfilename('fullpath');
if isempty(thisFile)
    st = dbstack('-completenames');
    thisFile = st(1).file;
end
repoRoot = fileparts(fileparts(thisFile));
modelName = 'acc_mils';
modelPath = fullfile(repoRoot, 'model', [modelName '.slx']);
dictPath = fullfile(repoRoot, 'data', 'acc_params.sldd');

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist(modelPath, 'file')
    delete(modelPath);
end

new_system(modelName);
open_system(modelName);

% Dictionary link with conservative fallback.
[~, dictFile, dictExt] = fileparts(dictPath);
dictNameOnly = [dictFile dictExt];
try
    set_param(modelName, 'DataDictionary', dictPath);
catch
    set_param(modelName, 'DataDictionary', dictNameOnly);
end

set_param(modelName, ...
    'SolverType', 'Fixed-step', ...
    'Solver', 'FixedStepDiscrete', ...
    'FixedStep', 'Ts', ...
    'StopTime', 'StopTime');

%-------------------------
% Top-level subsystems
%-------------------------
add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/Inputs_Scenario'], ...
    'Position', [40 70 240 210]);
add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/ACC_Controller'], ...
    'Position', [320 40 720 320]);
add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/Plant'], ...
    'Position', [790 50 1180 300]);
add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/Monitor'], ...
    'Position', [1260 70 1480 280]);

buildInputsScenario([modelName '/Inputs_Scenario']);
buildACCController([modelName '/ACC_Controller']);
buildPlant([modelName '/Plant']);
buildMonitor([modelName '/Monitor']);

%-------------------------
% Top-level wiring
%-------------------------
localAddNamedLine(modelName, 'Inputs_Scenario/1', 'ACC_Controller/1', 'v_lead');
localAddNamedLine(modelName, 'Inputs_Scenario/2', 'ACC_Controller/2', 'v_set');

localAddNamedLine(modelName, 'Plant/1', 'ACC_Controller/3', 'v_ego');
localAddNamedLine(modelName, 'Plant/2', 'ACC_Controller/4', 'distance');

localAddNamedLine(modelName, 'ACC_Controller/1', 'Plant/1', 'acc_cmd');
localAddNamedLine(modelName, 'Inputs_Scenario/1', 'Plant/2', 'v_lead_plant');

localAddNamedLine(modelName, 'Plant/1', 'Monitor/1', 'v_ego_mon');
localAddNamedLine(modelName, 'Inputs_Scenario/1', 'Monitor/2', 'v_lead_mon');
localAddNamedLine(modelName, 'Plant/2', 'Monitor/3', 'distance_mon');
localAddNamedLine(modelName, 'ACC_Controller/2', 'Monitor/4', 'd_ref_mon');
localAddNamedLine(modelName, 'ACC_Controller/3', 'Monitor/5', 'e_gap_mon');
localAddNamedLine(modelName, 'ACC_Controller/4', 'Monitor/6', 'e_speed_mon');
localAddNamedLine(modelName, 'ACC_Controller/5', 'Monitor/7', 'a_gap_mon');
localAddNamedLine(modelName, 'ACC_Controller/6', 'Monitor/8', 'a_speed_mon');
localAddNamedLine(modelName, 'ACC_Controller/1', 'Monitor/9', 'acc_cmd_mon');
localAddNamedLine(modelName, 'ACC_Controller/7', 'Monitor/10', 'mode_mon');

save_system(modelName, modelPath);
close_system(modelName);

fprintf('[make_model_02] created: %s\n', modelPath);

function buildInputsScenario(ss)
open_system(ss);

delete_block([ss '/In1']);
delete_block([ss '/Out1']);

add_block('simulink/Sources/From Workspace', [ss '/v_lead_from_ws'], ...
    'Position', [40 48 210 82], ...
    'VariableName', 'vL_ts', ...
    'SampleTime', '-1', ...
    'Interpolate', 'off', ...
    'OutputAfterFinalValue', 'Holding final value');

add_block('simulink/Sources/Constant', [ss '/v_set_const'], ...
    'Position', [40 128 120 152], 'Value', 'vSet');

add_block('simulink/Sinks/Out1', [ss '/v_lead'], 'Position', [280 55 310 75]);
add_block('simulink/Sinks/Out1', [ss '/v_set'], 'Position', [280 130 310 150]);

localAddNamedLine(ss, 'v_lead_from_ws/1', 'v_lead/1', 'v_lead');
localAddNamedLine(ss, 'v_set_const/1', 'v_set/1', 'v_set');
end

function buildACCController(ss)
open_system(ss);

delete_block([ss '/In1']);
delete_block([ss '/Out1']);

% Interface
add_block('simulink/Sources/In1', [ss '/v_lead'], 'Position', [30 40 60 60]);
add_block('simulink/Sources/In1', [ss '/v_set'], 'Position', [30 100 60 120]);
add_block('simulink/Sources/In1', [ss '/v_ego'], 'Position', [30 160 60 180]);
add_block('simulink/Sources/In1', [ss '/distance'], 'Position', [30 220 60 240]);

outNames = {'acc_cmd','d_ref','e_gap','e_speed','a_gap','a_speed','mode'};
for i = 1:numel(outNames)
    add_block('simulink/Sinks/Out1', [ss '/' outNames{i}], ...
        'Position', [1220 40+60*(i-1) 1250 60+60*(i-1)]);
end

% Parameters
add_block('simulink/Sources/Constant', [ss '/d0_const'], ...
    'Position', [120 280 210 300], 'Value', 'd0');
add_block('simulink/Sources/Constant', [ss '/time_gap_const'], ...
    'Position', [120 315 210 335], 'Value', 'time_gap');
add_block('simulink/Sources/Constant', [ss '/Kv_const'], ...
    'Position', [120 350 210 370], 'Value', 'Kv');
add_block('simulink/Sources/Constant', [ss '/Kgap_const'], ...
    'Position', [120 385 210 405], 'Value', 'Kgap');
add_block('simulink/Sources/Constant', [ss '/Kdv_const'], ...
    'Position', [120 420 210 440], 'Value', 'Kdv');
add_block('simulink/Sources/Constant', [ss '/d_switch_const'], ...
    'Position', [120 455 210 475], 'Value', 'd_switch');
add_block('simulink/Sources/Constant', [ss '/amin_const'], ...
    'Position', [120 490 210 510], 'Value', 'amin');
add_block('simulink/Sources/Constant', [ss '/amax_const'], ...
    'Position', [120 525 210 545], 'Value', 'amax');

% RelativeSpeed: dv = v_lead - v_ego
add_block('simulink/Math Operations/Sum', [ss '/RelativeSpeed'], ...
    'Position', [250 45 285 75], 'Inputs', '+-');

% DesiredGap: d_ref = d0 + time_gap * v_ego
add_block('simulink/Math Operations/Product', [ss '/DesiredGap_Product'], ...
    'Position', [250 140 290 170]);
add_block('simulink/Math Operations/Sum', [ss '/DesiredGap'], ...
    'Position', [330 140 365 170], 'Inputs', '++');

% GapError: e_gap = distance - d_ref
add_block('simulink/Math Operations/Sum', [ss '/GapError'], ...
    'Position', [420 210 455 240], 'Inputs', '+-');

% SpeedError: e_speed = v_set - v_ego
add_block('simulink/Math Operations/Sum', [ss '/SpeedError'], ...
    'Position', [420 100 455 130], 'Inputs', '+-');

% SpeedControl: a_speed = Kv * e_speed
add_block('simulink/Math Operations/Product', [ss '/SpeedControl'], ...
    'Position', [500 100 540 130]);

% GapControl: a_gap = Kgap*e_gap + Kdv*(v_lead-v_ego)
add_block('simulink/Math Operations/Product', [ss '/GapControl_GapTerm'], ...
    'Position', [500 200 540 230]);
add_block('simulink/Math Operations/Product', [ss '/GapControl_RelTerm'], ...
    'Position', [500 45 540 75]);
add_block('simulink/Math Operations/Sum', [ss '/GapControl'], ...
    'Position', [580 145 615 175], 'Inputs', '++');

% ModeLogic (distance < d_switch): 1 = gap mode, 0 = speed mode
add_block('simulink/Logic and Bit Operations/Compare To Constant', [ss '/ModeLogic_Compare'], ...
    'Position', [640 240 760 280], ...
    'relop', '<', 'const', 'd_switch', 'OutDataTypeStr', 'boolean');

% Select control target based on mode
add_block('simulink/Signal Routing/Switch', [ss '/ModeLogic_SelectCmd'], ...
    'Position', [700 145 740 185], 'Threshold', '0.5', 'Criteria', 'u2 >= Threshold');

% CommandLimit
add_block('simulink/Discontinuities/Saturation', [ss '/CommandLimit'], ...
    'Position', [820 145 870 185], 'LowerLimit', 'amin', 'UpperLimit', 'amax');

% Convert mode to double for monitor/logging portability.
add_block('simulink/Signal Attributes/Data Type Conversion', [ss '/Mode_ToDouble'], ...
    'Position', [820 245 900 275], 'OutDataTypeStr', 'double');

% Wires
localAddNamedLine(ss, 'v_lead/1', 'RelativeSpeed/1', 'v_lead');
localAddNamedLine(ss, 'v_ego/1', 'RelativeSpeed/2', 'v_ego');

localAddNamedLine(ss, 'time_gap_const/1', 'DesiredGap_Product/1', 'time_gap');
localAddNamedLine(ss, 'v_ego/1', 'DesiredGap_Product/2', 'v_ego_for_dref');
localAddNamedLine(ss, 'd0_const/1', 'DesiredGap/1', 'd0');
localAddNamedLine(ss, 'DesiredGap_Product/1', 'DesiredGap/2', 'tg_mul_v');
localAddNamedLine(ss, 'DesiredGap/1', 'd_ref/1', 'd_ref');

localAddNamedLine(ss, 'distance/1', 'GapError/1', 'distance');
localAddNamedLine(ss, 'DesiredGap/1', 'GapError/2', 'd_ref_to_gaperr');
localAddNamedLine(ss, 'GapError/1', 'e_gap/1', 'e_gap');

localAddNamedLine(ss, 'v_set/1', 'SpeedError/1', 'v_set');
localAddNamedLine(ss, 'v_ego/1', 'SpeedError/2', 'v_ego_for_espeed');
localAddNamedLine(ss, 'SpeedError/1', 'e_speed/1', 'e_speed');

localAddNamedLine(ss, 'Kv_const/1', 'SpeedControl/1', 'Kv');
localAddNamedLine(ss, 'SpeedError/1', 'SpeedControl/2', 'e_speed_to_ctrl');
localAddNamedLine(ss, 'SpeedControl/1', 'a_speed/1', 'a_speed');

localAddNamedLine(ss, 'Kgap_const/1', 'GapControl_GapTerm/1', 'Kgap');
localAddNamedLine(ss, 'GapError/1', 'GapControl_GapTerm/2', 'e_gap_to_ctrl');
localAddNamedLine(ss, 'Kdv_const/1', 'GapControl_RelTerm/1', 'Kdv');
localAddNamedLine(ss, 'RelativeSpeed/1', 'GapControl_RelTerm/2', 'dv');
localAddNamedLine(ss, 'GapControl_GapTerm/1', 'GapControl/1', 'gap_term');
localAddNamedLine(ss, 'GapControl_RelTerm/1', 'GapControl/2', 'rel_term');
localAddNamedLine(ss, 'GapControl/1', 'a_gap/1', 'a_gap');

localAddNamedLine(ss, 'distance/1', 'ModeLogic_Compare/1', 'distance_to_mode');
localAddNamedLine(ss, 'ModeLogic_Compare/1', 'Mode_ToDouble/1', 'mode_bool');
localAddNamedLine(ss, 'Mode_ToDouble/1', 'mode/1', 'mode');

localAddNamedLine(ss, 'SpeedControl/1', 'ModeLogic_SelectCmd/1', 'a_speed_sel');
localAddNamedLine(ss, 'Mode_ToDouble/1', 'ModeLogic_SelectCmd/2', 'mode_sel');
localAddNamedLine(ss, 'GapControl/1', 'ModeLogic_SelectCmd/3', 'a_gap_sel');

localAddNamedLine(ss, 'ModeLogic_SelectCmd/1', 'CommandLimit/1', 'a_raw_cmd');
localAddNamedLine(ss, 'CommandLimit/1', 'acc_cmd/1', 'acc_cmd');
end

function buildPlant(ss)
open_system(ss);

delete_block([ss '/In1']);
delete_block([ss '/Out1']);

% Interface
add_block('simulink/Sources/In1', [ss '/acc_cmd'], 'Position', [30 155 60 175]);
add_block('simulink/Sources/In1', [ss '/v_lead'], 'Position', [30 235 60 255]);
add_block('simulink/Sources/Constant', [ss '/Ts_const'], ...
    'Position', [90 320 165 340], 'Value', 'Ts');
% States
add_block('simulink/Discrete/Unit Delay', [ss '/v_ego_state'], ...
    'Position', [820 70 860 100], 'SampleTime', 'Ts', 'InitialCondition', 'vE0');
add_block('simulink/Discrete/Unit Delay', [ss '/distance_state'], ...
    'Position', [820 220 860 250], 'SampleTime', 'Ts', 'InitialCondition', 'd_init');

% v_ego update: v_ego_next = sat(v_ego + acc_cmd*Ts, [0, inf))
add_block('simulink/Math Operations/Product', [ss '/vE_Update_AccMulTs'], ...
    'Position', [180 150 220 180]);
add_block('simulink/Math Operations/Sum', [ss '/vE_Update_Sum'], ...
    'Position', [270 120 305 150], 'Inputs', '++');
add_block('simulink/Discontinuities/Saturation', [ss '/vE_Update_Saturation'], ...
    'Position', [350 120 410 150], 'LowerLimit', '0', 'UpperLimit', 'inf');

% distance update: d_next = sat(distance + (v_lead-v_ego)*Ts, [0, inf))
add_block('simulink/Math Operations/Sum', [ss '/Distance_RelSpeed'], ...
    'Position', [180 235 220 265], 'Inputs', '+-');
add_block('simulink/Math Operations/Product', [ss '/Distance_RelMulTs'], ...
    'Position', [270 235 310 265]);
add_block('simulink/Math Operations/Sum', [ss '/Distance_Update_Sum'], ...
    'Position', [350 205 385 235], 'Inputs', '++');
add_block('simulink/Discontinuities/Saturation', [ss '/Distance_Update_Saturation'], ...
    'Position', [430 205 490 235], 'LowerLimit', '0', 'UpperLimit', 'inf');

add_block('simulink/Sinks/Out1', [ss '/v_ego'], 'Position', [920 75 950 95]);
add_block('simulink/Sinks/Out1', [ss '/distance'], 'Position', [920 225 950 245]);

% Wiring
localAddNamedLine(ss, 'acc_cmd/1', 'vE_Update_AccMulTs/1', 'acc_cmd');
localAddNamedLine(ss, 'Ts_const/1', 'vE_Update_AccMulTs/2', 'Ts');
localAddNamedLine(ss, 'v_ego_state/1', 'vE_Update_Sum/1', 'v_ego_state');
localAddNamedLine(ss, 'vE_Update_AccMulTs/1', 'vE_Update_Sum/2', 'delta_v');
localAddNamedLine(ss, 'vE_Update_Sum/1', 'vE_Update_Saturation/1', 'v_ego_next_raw');
localAddNamedLine(ss, 'vE_Update_Saturation/1', 'v_ego_state/1', 'v_ego_next');

localAddNamedLine(ss, 'v_lead/1', 'Distance_RelSpeed/1', 'v_lead');
localAddNamedLine(ss, 'v_ego_state/1', 'Distance_RelSpeed/2', 'v_ego_for_distance');
localAddNamedLine(ss, 'Distance_RelSpeed/1', 'Distance_RelMulTs/1', 'v_rel');
localAddNamedLine(ss, 'Ts_const/1', 'Distance_RelMulTs/2', 'Ts_for_distance');
localAddNamedLine(ss, 'distance_state/1', 'Distance_Update_Sum/1', 'distance_state');
localAddNamedLine(ss, 'Distance_RelMulTs/1', 'Distance_Update_Sum/2', 'delta_d');
localAddNamedLine(ss, 'Distance_Update_Sum/1', 'Distance_Update_Saturation/1', 'distance_next_raw');
localAddNamedLine(ss, 'Distance_Update_Saturation/1', 'distance_state/1', 'distance_next');

localAddNamedLine(ss, 'v_ego_state/1', 'v_ego/1', 'v_ego');
localAddNamedLine(ss, 'distance_state/1', 'distance/1', 'distance');
end

function buildMonitor(ss)
open_system(ss);

delete_block([ss '/In1']);
delete_block([ss '/Out1']);

sigNames = {'v_ego','v_lead','distance','d_ref','e_gap','e_speed','a_gap','a_speed','acc_cmd','mode'};
wsNames = {'vE_log','vL_log','d_log','dRef_log','eGap_log','eSpeed_log','aGap_log','aSpeed_log','aCmd_log','mode_log'};

for i = 1:numel(sigNames)
    y = 30 + 45*(i-1);
    add_block('simulink/Sources/In1', [ss '/' sigNames{i}], 'Position', [30 y 60 y+20]);
    add_block('simulink/Sinks/To Workspace', [ss '/ToWs_' sigNames{i}], ...
        'Position', [200 y 350 y+25], ...
        'VariableName', wsNames{i}, ...
        'SaveFormat', 'Structure With Time');
    localAddNamedLine(ss, [sigNames{i} '/1'], ['ToWs_' sigNames{i} '/1'], sigNames{i});
end
end

function localAddNamedLine(sys, src, dst, sigName)
h = add_line(sys, src, dst, 'autorouting', 'on');
if nargin >= 4 && ~isempty(sigName)
    set_param(h, 'Name', sigName);
end
end
