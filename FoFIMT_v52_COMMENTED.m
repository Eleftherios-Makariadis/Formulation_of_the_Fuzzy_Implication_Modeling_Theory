% FoFIMT_v52
% Main entry point: initializes the FoFIMT GUI, state variables, and
% computational workflow for single-instance evaluation, BI, IMV, and the designer.
function FoFIMT_v52

% -------------------------------------------------------------------------
% Figure and global UI styling. The light tinting improves legibility in
% screenshots and printed figures used in the accompanying manuscript.
% -------------------------------------------------------------------------
% Slightly tinted background to help the screenshots of the window stand out in documents.
figBG    = [0.94 0.96 0.98];
dialogBG = [0.95 0.97 1.00]; % subtle tint for all dialog windows
scr = get(0,'ScreenSize');
figW = 1100;
figH = 700;
figX = (scr(3)-figW)/2;
figY = (scr(4)-figH)/2;

fig = figure('Name','FoFIMT_v52','NumberTitle','off','Color',figBG, ...
    'Position',[figX figY figW figH], ...
    'WindowKeyPressFcn',@onMainKeyPress);

% Primary visualization axes for single-instance evaluation and index plots.
ax = axes(fig,'Units','normalized','Position',[0.55 0.10 0.40 0.85]);
view(ax,[45 30]);
grid(ax,'on');

% -------------------------------------------------------------------------
% Mode selection drives which workflow is active (Single, BI, IMV, Designer)
% and therefore which panels and controls are visible.
% -------------------------------------------------------------------------
uicontrol(fig,'Style','text','String','Program Mode:', ...
    'Units','normalized','Position',[0.05 0.94 0.11 0.04], ...
    'HorizontalAlignment','left','BackgroundColor',figBG,'FontWeight','bold');

modePopup = uicontrol(fig,'Style','popupmenu', ...
    'String',{'Single F.I.M. Instance','F.I.M. Behavior Index (BI)', ...
    'F.I.M. Intra-Model Variability Index (IMV)','F.I.M. Designer'}, ...
    'Units','normalized','Position',[0.16 0.94 0.34 0.045], ...
    'Callback',@modeChanged,'FontWeight','bold');

bigExprPanel = uipanel('Parent',fig,'Title','F.I.M. Designer - Formula Preview', ...
    'Units','normalized','Position',[0.06 0.84 0.88 0.09], ...
    'BackgroundColor',[0.97 0.98 1.00],'ForegroundColor',[0.10 0.25 0.50], ...
    'FontWeight','bold','Visible','off');

bigExprText = uicontrol(bigExprPanel,'Style','text','String','(empty)', ...
    'Units','normalized','Position',[0.02 0.10 0.96 0.80], ...
    'BackgroundColor',[0.97 0.98 1.00],'ForegroundColor',[0.05 0.10 0.25], ...
    'HorizontalAlignment','center','FontSize',22,'FontWeight','bold', ...
    'FontName','Monospaced');

lblStruct = uicontrol(fig,'Style','text','String','F.I.M.:', ...
    'Units','normalized','Position',[0.05 0.83 0.10 0.05], ...
    'HorizontalAlignment','left','BackgroundColor',figBG);

% -------------------------------------------------------------------------
% Operator and structural presets for F.I.M. specification.
% -------------------------------------------------------------------------
structPopup = uicontrol(fig,'Style','popupmenu','String', ...
    {'S(N(x),y)', ...
    'S(y,S(N(x),T(y,y)))'}, ...
    'Units','normalized','Position',[0.16 0.84 0.34 0.05]);

appendPersistentFIMs();

lblS = uicontrol(fig,'Style','text','String','Fuzzy Disjunction S(x,y):', ...
    'Units','normalized','Position',[0.05 0.74 0.18 0.05], ...
    'HorizontalAlignment','left','BackgroundColor',figBG);
itemsS = {'max(x,y)','x+y-x*y','min(x+y,1)'};
S_popup = uicontrol(fig,'Style','popupmenu','String',itemsS, ...
    'Units','normalized','Position',[0.24 0.75 0.26 0.05]);

lblT = uicontrol(fig,'Style','text','String','Fuzzy Conjunction T(x,y):', ...
    'Units','normalized','Position',[0.05 0.64 0.18 0.05], ...
    'HorizontalAlignment','left','BackgroundColor',figBG);
itemsT = {'min(x,y)','x*y','max(x+y-1,0)'};
T_popup = uicontrol(fig,'Style','popupmenu','String',itemsT, ...
    'Units','normalized','Position',[0.24 0.65 0.26 0.05]);

lblN = uicontrol(fig,'Style','text','String','Fuzzy Negation N(x):', ...
    'Units','normalized','Position',[0.05 0.54 0.18 0.05], ...
    'HorizontalAlignment','left','BackgroundColor',figBG);
itemsN = {'1-x','(1-x)/(1+lambda*x)','(1-x^w)^(1/w)'};
N_popup = uicontrol(fig,'Style','popupmenu','String',itemsN, ...
    'Units','normalized','Position',[0.24 0.55 0.26 0.05], ...
    'Callback',@negChanged);

lambdaY = 0.46;
wY      = 0.38;

lambdaLabel = uicontrol(fig,'Style','text','String','λ Parameter:', ...
    'Units','normalized','Position',[0.05 lambdaY 0.18 0.05], ...
    'HorizontalAlignment','left','BackgroundColor',figBG,'Visible','off');

lambdaEdit  = uicontrol(fig,'Style','edit','String','1','Units','normalized', ...
    'Position',[0.24 lambdaY+0.005 0.26 0.05],'Visible','off');

wLabel = uicontrol(fig,'Style','text','String','w Parameter:', ...
    'Units','normalized','Position',[0.05 wY 0.18 0.05], ...
    'HorizontalAlignment','left','BackgroundColor',figBG,'Visible','off');

wEdit  = uicontrol(fig,'Style','edit','String','1','Units','normalized', ...
    'Position',[0.24 wY+0.005 0.26 0.05],'Visible','off');

% -------------------------------------------------------------------------
% Primary actions: compute and export results.
% -------------------------------------------------------------------------
runBtn = uicontrol(fig,'Style','pushbutton','String','Compute', ...
    'FontSize',12,'FontWeight','bold','BackgroundColor',[0.20 0.45 0.90], ...
    'ForegroundColor',[1 1 1],'Units','normalized', ...
    'Position',[0.05 0.14 0.21 0.08],'Callback',@onRun);

downloadBtn = uicontrol(fig,'Style','pushbutton','String','Download Index', ...
    'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',[0.80 0.80 0.80], ...
    'ForegroundColor',[1 1 1],'Units','normalized', ...
    'Position',[0.29 0.14 0.21 0.08],'Callback',@onDownloadIndex, ...
    'Enable','off','Visible','off');

previewTable = uitable(fig,'Units','normalized', ...
    'Position',[0.05 0.27 0.45 0.39], ...
    'Visible','off', ...
    'ColumnName',{},'RowName',{});

% -------------------------------------------------------------------------
% Configuration management for BI/IMV: load, edit, save, and delete.
% -------------------------------------------------------------------------
configLabel = uicontrol(fig,'Style','text', ...
    'String','Saved Index Configurations:', ...
    'Units','normalized','Position',[0.05 0.86 0.18 0.03], ...
    'HorizontalAlignment','left','BackgroundColor',figBG, ...
    'FontWeight','bold','Visible','off');

configPopup = uicontrol(fig,'Style','popupmenu', ...
    'String',{'New Configuration'}, ...
    'Units','normalized','Position',[0.24 0.86 0.26 0.035], ...
    'Visible','off','FontWeight','bold', ...
    'BackgroundColor',[1 1 1], ...
    'Callback',@onConfigSelection);

saveCfgBtn = uicontrol(fig,'Style','pushbutton','String','Save Configuration', ...
    'Units','normalized','Position',[0.24 0.82 0.26 0.035], ...
    'Visible','off','Enable','off','FontWeight','bold', ...
    'BackgroundColor',[0.80 0.80 0.80],'ForegroundColor',[1 1 1], ...
    'Callback',@onSaveConfig);

editCfgBtn = uicontrol(fig,'Style','pushbutton','String','Edit Configuration...', ...
    'Units','normalized','Position',[0.24 0.78 0.26 0.035], ...
    'Visible','off','Enable','off','FontWeight','bold', ...
    'BackgroundColor',[0.80 0.80 0.80],'ForegroundColor',[1 1 1], ...
    'Callback',@onEditConfig);

deleteCfgBtn = uicontrol(fig,'Style','pushbutton','String','Delete Configuration', ...
    'Units','normalized','Position',[0.24 0.74 0.26 0.035], ...
    'Visible','off','Enable','off','FontWeight','bold', ...
    'BackgroundColor',[0.80 0.80 0.80],'ForegroundColor',[1 1 1], ...
    'Callback',@onDeleteConfig);

indexViewLabel = uicontrol(fig,'Style','text', ...
    'String','Plot View:', ...
    'Units','normalized','Position',[0.05 0.70 0.18 0.03], ...
    'HorizontalAlignment','left','BackgroundColor',figBG, ...
    'FontWeight','bold','Visible','off');

indexViewPopup = uicontrol(fig,'Style','popupmenu', ...
    'String',{'Auto (MATLAB Default)','[0,1]^3 Cube'}, ...
    'Units','normalized','Position',[0.24 0.70 0.26 0.035], ...
    'Visible','off','FontWeight','bold', ...
    'BackgroundColor',[1 1 1], ...
    'Callback',@onIMVViewChanged);

% -------------------------------------------------------------------------
% Designer panel: interactive tree-based construction of F.I.M. formulas.
% -------------------------------------------------------------------------
panelBG = [0.96 0.98 1.00];
builderPanel = uipanel('Parent',fig,'Title','F.I.M. Designer', ...
    'Units','normalized','Position',[0.05 0.18 0.90 0.64], ...
    'Visible','off','BackgroundColor',panelBG, ...
    'FontWeight','bold','ForegroundColor',[0.10 0.25 0.50]);

uicontrol(builderPanel,'Style','text', ...
    'String','Click a Node or Use Arrows to Select. Then use the Pieces on the Right or your Keyboard Keys (x,y,s,t,n) to build your F.I.M.', ...
    'Units','normalized','Position',[0.02 0.92 0.96 0.06], ...
    'BackgroundColor',panelBG,'ForegroundColor',[0.10 0.25 0.50], ...
    'FontWeight','bold','HorizontalAlignment','left');

axBuild = axes(builderPanel,'Units','normalized','Position',[0.02 0.20 0.58 0.70]);
axis(axBuild,[0 1 0 1]);
axis(axBuild,'off');
hold(axBuild,'on');

piecesPanel = uipanel('Parent',builderPanel,'Title','Pieces', ...
    'Units','normalized','Position',[0.62 0.30 0.36 0.62], ...
    'BackgroundColor',panelBG,'ForegroundColor',[0.10 0.25 0.50], ...
    'FontWeight','bold');

makeBtn(piecesPanel,'S(x,y)','S',[0.07 0.68 0.38 0.24],[0.85 0.93 1.00],[0.05 0.25 0.55]);
makeBtn(piecesPanel,'T(x,y)','T',[0.55 0.68 0.38 0.24],[0.88 1.00 0.88],[0.10 0.55 0.10]);
makeBtn(piecesPanel,'N(x)','N',[0.07 0.38 0.38 0.24],[1.00 0.95 0.85],[0.65 0.40 0.05]);
makeBtn(piecesPanel,'x','x',[0.55 0.38 0.38 0.24],[0.90 0.92 1.00],[0.10 0.10 0.45]);
makeBtn(piecesPanel,'y','y',[0.31 0.12 0.38 0.20],[1.00 0.92 0.96],[0.55 0.10 0.35]);

uicontrol(piecesPanel,'Style','pushbutton','String','Clear Subtree', ...
    'Units','normalized','Position',[0.07 0.02 0.38 0.08], ...
    'FontWeight','bold','BackgroundColor',[0.92 0.92 0.92], ...
    'Callback',@(~,~) clearSubtree());

uicontrol(piecesPanel,'Style','pushbutton','String','Reset Tree', ...
    'Units','normalized','Position',[0.55 0.02 0.38 0.08], ...
    'FontWeight','bold','BackgroundColor',[0.92 0.92 0.92], ...
    'Callback',@(~,~) initPuzzle());

actionsPanel = uipanel('Parent',builderPanel,'Title','Actions', ...
    'Units','normalized','Position',[0.02 0.02 0.96 0.18], ...
    'BackgroundColor',panelBG,'ForegroundColor',[0.10 0.25 0.50], ...
    'FontWeight','bold');

btnH = 0.60;
btnY = 0.20;

uicontrol(actionsPanel,'Style','pushbutton','String','Duplicate F.I.M. Check', ...
    'Units','normalized','Position',[0.02 btnY 0.30 btnH], ...
    'FontWeight','bold','BackgroundColor',[0.20 0.65 0.20], ...
    'ForegroundColor',[1 1 1], 'Callback',@(~,~) onDuplicateCheck());

uicontrol(actionsPanel,'Style','pushbutton','String','Load F.I.M. From List...', ...
    'Units','normalized','Position',[0.35 btnY 0.30 btnH], ...
    'FontWeight','bold','BackgroundColor',[0.20 0.45 0.90], ...
    'ForegroundColor',[1 1 1], 'Callback',@(~,~) loadFIMFromList());

uicontrol(actionsPanel,'Style','pushbutton','String','Add F.I.M. to List...', ...
    'Units','normalized','Position',[0.68 btnY 0.30 btnH], ...
    'FontWeight','bold','BackgroundColor',[0.20 0.45 0.90], ...
    'ForegroundColor',[1 1 1], 'Callback',@(~,~) addCurrentToFIM());

% -------------------------------------------------------------------------
% State initialization and persistence hooks.
% -------------------------------------------------------------------------
singleControls = [lblStruct, structPopup];

presetStruct = structPopup.String{1};
presetS      = itemsS{1};
presetT      = itemsT{1};
presetN      = itemsN{1};
presetLam    = 1;
presetW      = 1;

nodes = struct([]);
selectedNode = 1;

indexConfigs     = loadPersistentConfigs();
lastConfigIdxBI  = [];
lastConfigIdxIMV = [];

pendingConfigBI  = [];
pendingConfigIMV = [];

rebuildConfigPopup();

initPuzzle();
modeChanged();

    % Create a standardized piece button in the designer panel and bind it to addPiece.
    function makeBtn(parent,label,piece,pos,bg,fg)
        uicontrol(parent,'Style','pushbutton','String',label, ...
            'Units','normalized','Position',pos,'FontWeight','bold', ...
            'BackgroundColor',bg,'ForegroundColor',fg, ...
            'Callback',@(~,~) addPiece(piece));
    end

    % Toggle visibility of negation-parameter controls based on the selected N(x) form and mode.
    function negChanged(~,~)
        sel = N_popup.Value;
        m   = modePopup.Value;
        isSingle   = (m == 1);
        isDesigner = (m == 4);
        showLam = (sel==2) && (isSingle || isDesigner);
        showW   = (sel==3) && (isSingle || isDesigner);
        set(lambdaLabel,'Visible', onOff(showLam));
        set(lambdaEdit ,'Visible', onOff(showLam));
        set(wLabel,'Visible', onOff(showW));
        set(wEdit ,'Visible', onOff(showW));
    end

    % Reset the main visualization axes to a clean, neutral state (labels, view, grid, colorbar).
    function clearMainAxes()
        if ~ishandle(ax)
            return;
        end
        cla(ax);
        title(ax,'');
        xlabel(ax,'');
        ylabel(ax,'');
        zlabel(ax,'');
        cb = findall(fig,'Type','ColorBar');
        delete(cb);
        axis(ax,'auto');
        daspect(ax,'auto');
        grid(ax,'on');
        view(ax,[45 30]);
    end

    % Switch the GUI between program modes, update control visibility, and refresh previews.
    function modeChanged(~,~)
        m = modePopup.Value;
        isSingle   = (m == 1);
        isBI       = (m == 2);
        isIMV      = (m == 3);
        isIndex    = (isBI || isIMV);
        isDesigner = (m == 4);
        clearMainAxes();
        set(previewTable,'Data',[]);
        set(previewTable,'ColumnName',{},'RowName',{});
        set(downloadBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(editCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(deleteCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        if isIndex
            set(configPopup,'Value',1);
            onConfigSelection([],[]);
        end
        setVisible(singleControls, isSingle);
        set(previewTable ,'Visible', onOff(isIndex));
        set(builderPanel ,'Visible', onOff(isDesigner));
        set(bigExprPanel,'Visible', onOff(isDesigner));
        setVisible([indexViewLabel, indexViewPopup], isIMV);
        setVisible([configLabel, configPopup, saveCfgBtn, editCfgBtn, deleteCfgBtn], isIndex);
        set(downloadBtn,'Visible',onOff(isIndex));
        if ~isIndex
            set(downloadBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        end
        showSTN = (isSingle || isDesigner);
        set([lblS,S_popup,lblT,T_popup,lblN,N_popup,lambdaLabel,lambdaEdit,wLabel,wEdit], ...
            'Visible', onOff(showSTN));
        negChanged();
        if isDesigner
            set(ax,'Visible','off');
            set(runBtn,'Visible','off');
        else
            set(ax,'Visible','on');
            set(runBtn,'Visible','on');
        end
        updateExprText();
    end

    % Enable or disable configuration editing controls based on the current dropdown selection.
    function onConfigSelection(~,~)
        strs = get(configPopup,'String');
        val  = get(configPopup,'Value');
        if ischar(strs)
            strs = cellstr(strs);
        end
        if val <= 1 || isempty(indexConfigs)
            set(editCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
            set(deleteCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        else
            set(editCfgBtn,'Enable','on','BackgroundColor',[0.20 0.45 0.90]);
            set(deleteCfgBtn,'Enable','on','BackgroundColor',[0.70 0.20 0.20]);
        end
    end

    % Adjust axis scaling for IMV plots (auto scaling versus the unit cube).
    function onIMVViewChanged(~,~)
        if modePopup.Value ~= 3
            return;
        end
        if ~ishandle(ax)
            return;
        end
        if indexViewPopup.Value == 2
            axis(ax,[0 1 0 1 0 1]);
            daspect(ax,[1 1 1]);
        else
            axis(ax,'auto');
            daspect(ax,'auto');
        end
    end

    % Export the current BI/IMV table to CSV or Excel with a timestamped filename.
    function onDownloadIndex(~,~)
        modeVal = modePopup.Value;
        if modeVal ~= 2 && modeVal ~= 3
            return;
        end
        data = get(previewTable,'Data');
        if isempty(data)
            return;
        end
        if modeVal == 2
            idxName = 'BI';
        else
            idxName = 'IMV';
        end
        fmt = chooseExportFormat(idxName);
        if strcmp(fmt,'cancel') || isempty(fmt)
            return;
        end
        ts = datestr(now,'yyyy-mm-dd_HHMMSS');
        defName = sprintf('%s_Results_%s',idxName,ts);
        try
            switch fmt
                case 'csv'
                    [file,path] = uiputfile({'*.csv','CSV file (*.csv)'}, ...
                        sprintf('Save %s as CSV',idxName), [defName '.csv']);
                    if isequal(file,0)
                        return;
                    end
                    fullFile = fullfile(path,file);
                    writematrix(data,fullFile);
                case 'excel'
                    [file,path] = uiputfile({'*.xlsx','Excel file (*.xlsx)'}, ...
                        sprintf('Save %s as Excel',idxName), [defName '.xlsx']);
                    if isequal(file,0)
                        return;
                    end
                    fullFile = fullfile(path,file);
                    writematrix(data,fullFile);
            end
            h = msgbox(sprintf('%s index saved to:\n%s',idxName,fullFile), ...
                'Index saved','help');
            attachEnterClose(h);
        catch ME
            h = errordlg(sprintf('Failed to save file:\n%s',ME.message), ...
                'Save error');
            attachEnterClose(h);
        end
    end

    % Modal dialog that lets the user choose an export format; returns the selection string.
    function fmt = chooseExportFormat(idxName)
        fmt = 'cancel';
        dlgW = 400;
        dlgH = 180;
        d = dialog('Name','Download Index', ...
            'Position',[0 0 dlgW dlgH], ...
            'WindowStyle','modal','Color',dialogBG);
        centerDialog(d,fig);
        uicontrol(d,'Style','text', ...
            'String',sprintf('Select Export Format for the %s Index:',idxName), ...
            'Position',[20 (dlgH-60)/2 dlgW-40 60], ...
            'BackgroundColor',dialogBG, ...
            'HorizontalAlignment','center','FontWeight','bold');
        btnY = 25;
        btnW = 90;
        btnH = 30;
        margin = 30;
        gap = (dlgW - 2*margin - 3*btnW)/2;
        csvX   = margin;
        xlsxX  = margin + btnW + gap;
        cancelX= margin + 2*(btnW + gap);
        uicontrol(d,'Style','pushbutton','String','CSV', ...
            'Position',[csvX btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90], ...
            'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) onChoice('csv'));
        uicontrol(d,'Style','pushbutton','String','Excel', ...
            'Position',[xlsxX btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90], ...
            'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) onChoice('excel'));
        uicontrol(d,'Style','pushbutton','String','Cancel', ...
            'Position',[cancelX btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.92 0.92 0.92], ...
            'Callback',@(~,~) onChoice('cancel'));
        set(d,'WindowKeyPressFcn',@onKey);
        uiwait(d);
        if ishghandle(d)
            delete(d);
        end
        % Local dialog callback to capture the user's selection and resume execution.
        function onChoice(c)
            fmt = c;
            uiresume(d);
        end
        % Local dialog key handler for Enter/Escape shortcuts.
        function onKey(~,evt)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                onChoice('excel');
            elseif strcmp(evt.Key,'escape')
                onChoice('cancel');
            end
        end
    end

    % Persist or update the active index configuration and synchronize UI state.
    function onSaveConfig(~,~)
        modeVal = modePopup.Value;
        if modeVal~=2 && modeVal~=3
            return;
        end
        isBI  = (modeVal==2);
        if isBI
            idx     = lastConfigIdxBI;
            pendCfg = pendingConfigBI;
        else
            idx     = lastConfigIdxIMV;
            pendCfg = pendingConfigIMV;
        end
        if isempty(idx) || idx<1 || idx>numel(indexConfigs)
            if isempty(pendCfg)
                h = warndlg('No Configuration Available to Save. Run an Index First...', ...
                    'No Configuration');
                attachEnterClose(h);
                return;
            end
            existing = {indexConfigs.name};
            if any(strcmp(existing, pendCfg.name))
                pendCfg.name = uniqueConfigName(pendCfg.name);
            end
            pendCfg.original.name   = pendCfg.name;
            pendCfg.original.k      = pendCfg.k;
            pendCfg.original.n      = pendCfg.n;
            pendCfg.original.models = pendCfg.models;
            pendCfg.dirty           = false;
            cfgIdx = registerConfig(pendCfg);
            if isBI
                lastConfigIdxBI  = cfgIdx;
                pendingConfigBI  = [];
            else
                lastConfigIdxIMV = cfgIdx;
                pendingConfigIMV = [];
            end
            savePersistentConfigs();
            rebuildConfigPopup(pendCfg.name);
            set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
            set(deleteCfgBtn,'Enable','on','BackgroundColor',[0.70 0.20 0.20]);
            return;
        end
        cfg = indexConfigs(idx);
        isDirty = isfield(cfg,'dirty') && cfg.dirty;
        if ~isDirty
            savePersistentConfigs();
            set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
            return;
        end
        action = overrideNewDialog();
        if strcmp(action,'cancel')
            return;
        end
        if strcmp(action,'override')
            cfg.original.name   = cfg.name;
            cfg.original.k      = cfg.k;
            cfg.original.n      = cfg.n;
            cfg.original.models = cfg.models;
            cfg.dirty = false;
            indexConfigs(idx) = cfg;
            savePersistentConfigs();
            rebuildConfigPopup(cfg.name);
            set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        elseif strcmp(action,'new')
            newCfg = cfg;
            % If only the name changed, allow reuse without suffix.
            % If the name stayed the same (only other fields changed), force a suffix.
            sameNameAsOriginal = isfield(cfg,'original') && ~isempty(cfg.original) && ...
                isfield(cfg.original,'name') && strcmp(cfg.name, cfg.original.name);
            if sameNameAsOriginal
                newCfg.name = uniqueConfigName(cfg.name); % include current entry, will append (2)/(3)...
            else
                newCfg.name = uniqueConfigName(cfg.name, idx); % exclude self to keep unique renamed value
            end
            newCfg.original.name   = newCfg.name;
            newCfg.original.k      = newCfg.k;
            newCfg.original.n      = newCfg.n;
            newCfg.original.models = newCfg.models;
            newCfg.dirty = false;
            if isfield(cfg,'original') && ~isempty(cfg.original)
                cfgRevert = cfg;
                if isfield(cfg.original,'name') && ~isempty(cfg.original.name)
                    cfgRevert.name = cfg.original.name;
                end
                cfgRevert.k      = cfg.original.k;
                cfgRevert.n      = cfg.original.n;
                cfgRevert.models = cfg.original.models;
                cfgRevert.dirty  = false;
                indexConfigs(idx) = cfgRevert;
            else
                cfg.dirty = false;
                indexConfigs(idx) = cfg;
            end
            indexConfigs(end+1) = newCfg;
            newIdx = numel(indexConfigs);
            savePersistentConfigs();
            rebuildConfigPopup(newCfg.name);
            if isBI
                lastConfigIdxBI = newIdx;
            else
                lastConfigIdxIMV = newIdx;
            end
            set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
            set(deleteCfgBtn,'Enable','on','BackgroundColor',[0.70 0.20 0.20]);
        end
    end

    % Prompt to confirm whether a pending configuration should be overridden by a new one.
    function action = overrideNewDialog()
        action = 'cancel';
        dlgW = 460;
        dlgH = 190;
        d = dialog('Name','Save Configuration', ...
            'Position',[0 0 dlgW dlgH],'WindowStyle','modal','Color',dialogBG);
        centerDialog(d,fig);
        set(d,'WindowKeyPressFcn',@onKey);
        uicontrol(d,'Style','text','String', ...
            'Do You Want to Overwrite the Existing Configuration, or Save Changes as a New One?',...
            'Position',[20 (dlgH-70)/2 dlgW-40 70],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','center','FontWeight','bold');
        btnY  = 25;
        btnW = 110;
        btnH = 30;
        margin = 30;
        gap = (dlgW - 2*margin - 3*btnW)/2;
        x1 = margin;
        x2 = margin + btnW + gap;
        x3 = margin + 2*(btnW + gap);
        uicontrol(d,'Style','pushbutton','String','Overwrite', ...
            'Position',[x1 btnY btnW btnH],'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90],'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) onChoice('override'));
        uicontrol(d,'Style','pushbutton','String','Save as New', ...
            'Position',[x2 btnY btnW btnH],'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90],'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) onChoice('new'));
        uicontrol(d,'Style','pushbutton','String','Cancel', ...
            'Position',[x3 btnY btnW btnH],'FontWeight','bold', ...
            'BackgroundColor',[0.92 0.92 0.92], ...
            'Callback',@(~,~) onChoice('cancel'));
        uiwait(d);
        if ishghandle(d)
            delete(d);
        end
        % Local dialog callback to capture the user's selection and resume execution.
        function onChoice(c)
            action = c;
            uiresume(d);
        end
        % Local dialog key handler for Enter/Escape shortcuts.
        function onKey(~,evt)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                onChoice('override');
            elseif strcmp(evt.Key,'escape')
                onChoice('cancel');
            end
        end
    end

    % Delete the selected configuration after confirmation and rebuild the dropdown list.
    function onDeleteConfig(~,~)
        modeVal = modePopup.Value;
        if modeVal~=2 && modeVal~=3
            return;
        end
        strs = get(configPopup,'String');
        val = get(configPopup,'Value');
        if val<=1 || isempty(indexConfigs)
            return;
        end
        idx = val-1;
        if idx<1 || idx>numel(indexConfigs)
            return;
        end
        choice = yesNoDialog('Delete the Selected Configuration Permanently?','Delete Configuration','No');
        if ~strcmp(choice,'Yes')
            return;
        end
        indexConfigs(idx) = [];
        if modeVal==2
            if ~isempty(lastConfigIdxBI) && lastConfigIdxBI==idx
                lastConfigIdxBI = [];
            end
        else
            if ~isempty(lastConfigIdxIMV) && lastConfigIdxIMV==idx
                lastConfigIdxIMV = [];
            end
        end
        savePersistentConfigs();
        rebuildConfigPopup();
        set(configPopup,'Value',1);
        set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(editCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(deleteCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
    end

    % Open the configuration editor dialog, apply edits, and mark dirty state when needed.
    function onEditConfig(~,~)
        modeVal = modePopup.Value;
        if modeVal~=2 && modeVal~=3
            return;
        end
        val = get(configPopup,'Value');
        if val<=1 || isempty(indexConfigs)
            h = warndlg('Select a Saved Configuration from the Dropdown First.', ...
                'No configuration selected');
            attachEnterClose(h);
            return;
        end
        idx = val-1;
        if idx<1 || idx>numel(indexConfigs)
            h = warndlg('Invalid Configuration Selection.','Error');
            attachEnterClose(h);
            return;
        end
        cfg = indexConfigs(idx);

        origName   = cfg.name;
        origK      = cfg.k;
        origN      = cfg.n;
        origModels = cfg.models;

        dlgW = 480;
        dlgH = 260;
        d = dialog('Name','Edit Index Configuration', ...
            'Position',[0 0 dlgW dlgH],'WindowStyle','modal','Color',dialogBG);
        centerDialog(d,fig);
        set(d,'WindowKeyPressFcn',@onKey);

        blockH = 82;
        yTop = dlgH/2 + blockH/2 - 22; % center the 3-row block vertically
        lblWidth = 120;
        valWidth = dlgW-40-lblWidth;
        xLbl = 20;
        xVal = xLbl + lblWidth + 10;

        uicontrol(d,'Style','text','String','Name:', ...
            'Position',[xLbl yTop lblWidth 22],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','right','FontWeight','bold');
        nameEdit = uicontrol(d,'Style','edit','String',cfg.name, ...
            'Position',[xVal yTop valWidth 22],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','left');

        yTop2 = yTop - 35;
        uicontrol(d,'Style','text','String','Index Depth k:', ...
            'Position',[xLbl yTop2 lblWidth 22],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','right','FontWeight','bold');
        depthEdit = uicontrol(d,'Style','edit', ...
            'String',num2str(cfg.k), ...
            'Position',[xVal yTop2 valWidth 22],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','left');

        yTop3 = yTop2 - 25;
        uicontrol(d,'Style','text','String','Index Degree n:', ...
            'Position',[xLbl yTop3 lblWidth 22],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','right','FontWeight','bold');
        degreeEdit = uicontrol(d,'Style','edit', ...
            'String',num2str(cfg.n), ...
            'Position',[xVal yTop3 valWidth 22],'BackgroundColor',dialogBG,...
            'HorizontalAlignment','left');

        btnY=20;
        btnW=120;
        btnH=30;
        margin=80;
        gap=(dlgW-2*margin-2*btnW);
        x1=margin;
        x2=margin+btnW+gap;

        uicontrol(d,'Style','pushbutton','String','Continue', ...
            'Position',[x1 btnY btnW btnH],'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90],'ForegroundColor',[1 1 1],...
            'Callback',@(~,~) continueEdit());
        uicontrol(d,'Style','pushbutton','String','Close', ...
            'Position',[x2 btnY btnW btnH],'FontWeight','bold', ...
            'BackgroundColor',[0.92 0.92 0.92],...
            'Callback',@(~,~) closeDlg());
        uiwait(d);
        if ishghandle(d)
            delete(d);
        end

        % Apply dialog edits to the configuration and update the UI/dirty markers.
        function continueEdit()
            newNm = strtrim(get(nameEdit,'String'));
            if isempty(newNm)
                newNm = cfg.name;
            end
            kVal = str2double(get(depthEdit,'String'));
            nVal = str2double(get(degreeEdit,'String'));
            if isnan(kVal) || kVal <= 1 || isnan(nVal) || nVal < 1
                h = warndlg('Please enter k>1 and n>=1.','Invalid Parameters');
                attachEnterClose(h);
                return;
            end
            newK = max(2,round(kVal));
            newN = max(1,round(nVal));

            models = cfg.models;
            if isempty(models)
                models(1,newN) = struct('struct','','S','','T','','N','','lambda',1,'w',1);
                for jj=1:newN
                    models(jj) = models(jj);
                end
            else
                oldN = numel(models);
                if newN > oldN
                    lastModel = models(end);
                    for jj=oldN+1:newN
                        models(jj) = lastModel;
                    end
                elseif newN < oldN
                    models = models(1:newN);
                end
            end

            modelsOriginal = models;
            nlocal = newN;
            if isempty(modelsOriginal) || numel(modelsOriginal)~=nlocal
                uiresume(d);
                return;
            end

            modelsWork = modelsOriginal;
            modelsWork(1) = configureInstance(modelsWork(1).struct, ...
                modelsWork(1).S,modelsWork(1).T,modelsWork(1).N, ...
                modelsWork(1).lambda,modelsWork(1).w, ...
                1,nlocal,false);
            lockedF = modelsWork(1).struct;
            for jj=2:nlocal
                modelsWork(jj) = configureInstance(lockedF, ...
                    modelsWork(jj).S,modelsWork(jj).T,modelsWork(jj).N, ...
                    modelsWork(jj).lambda,modelsWork(jj).w, ...
                    jj,nlocal,true);
            end

            nameChanged   = ~strcmp(newNm,origName);
            kChanged      = (newK ~= origK);
            nChanged      = (newN ~= origN);
            modelsChanged = ~isequal(modelsWork,origModels);

            changed = nameChanged || kChanged || nChanged || modelsChanged;

            if changed
                if ~isfield(cfg,'original') || isempty(cfg.original)
                    cfg.original.name   = origName;
                    cfg.original.k      = origK;
                    cfg.original.n      = origN;
                    cfg.original.models = origModels;
                end
                cfg.name   = newNm;
                cfg.k      = newK;
                cfg.n      = newN;
                cfg.models = modelsWork;
                cfg.dirty  = true;
                indexConfigs(idx) = cfg;
                rebuildConfigPopup(cfg.name);
                if strcmp(cfg.mode,'BI')
                    lastConfigIdxBI = idx;
                else
                    lastConfigIdxIMV = idx;
                end
                set(saveCfgBtn,'Enable','on','BackgroundColor',[0.20 0.45 0.90]);
            end

            if ishghandle(d)
                uiresume(d);
            end

            strsLocal = get(configPopup,'String');
            if ischar(strsLocal)
                strsLocal = cellstr(strsLocal);
            end
            valNew = find(strcmp(strsLocal,cfg.name) | ...
                strcmp(strsLocal,[cfg.name '*']),1);
            if isempty(valNew)
                rebuildConfigPopup(cfg.name);
                strsLocal = get(configPopup,'String');
                if ischar(strsLocal)
                    strsLocal = cellstr(strsLocal);
                end
                valNew = find(strcmp(strsLocal,cfg.name) | ...
                    strcmp(strsLocal,[cfg.name '*']),1);
                if isempty(valNew)
                    valNew = idx+1;
                end
            end
            set(configPopup,'Value',valNew);
            onRun([],[]);
        end

        % Close the configuration editor dialog and clean up its handle.
        function closeDlg()
            uiresume(d);
        end

        % Local dialog key handler for Enter/Escape shortcuts.
        function onKey(~,evt)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                continueEdit();
            elseif strcmp(evt.Key,'escape')
                closeDlg();
            end
        end
    end

    % Main execution entry: validate inputs, build operator handles, and compute the selected mode.
    function onRun(~,~)
        modeVal = modePopup.Value;
        if modeVal == 1
            clearMainAxes();
            structStr = structPopup.String{structPopup.Value};
            S_str     = S_popup.String{S_popup.Value};
            T_str     = T_popup.String{T_popup.Value};
            N_str     = N_popup.String{N_popup.Value};
            lamVal    = str2double(lambdaEdit.String);
            wVal      = str2double(wEdit.String);
            k = 50;
            coords = linspace(0,1,k);
            [X,Y] = meshgrid(coords,coords);
            f = buildHandle(structStr,S_str,T_str,N_str,lamVal,wVal);
            Z = f(X,Y);
            Z = max(min(Z,1),0);
            cla(ax);
            surf(ax,X,Y,Z);
            xlabel(ax,'x');
            ylabel(ax,'y');
            zlabel(ax,'I_m(x,y)');
            title(ax,'Single F.I.M. Instance');
            grid(ax,'on');
            axis(ax,[0 1 0 1 0 1]);
            daspect(ax,[1 1 1]);
            view(ax,[45 30]);
            return;
        end
        clearMainAxes();
        set(previewTable,'Data',[]);
        set(previewTable,'ColumnName',{},'RowName',{});
        set(downloadBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(editCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        set(deleteCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        isBI  = (modeVal == 2);
        isIMV = (modeVal == 3);
        cfgSelIdx = get(configPopup,'Value');
        useSavedCfg = (cfgSelIdx > 1) && ~isempty(indexConfigs);
        if isBI
            pendingConfigBI = [];
        else
            pendingConfigIMV = [];
        end
        if useSavedCfg
            cfgIdx = cfgSelIdx-1;
            cfg = indexConfigs(cfgIdx);
            k   = cfg.k;
            n   = cfg.n;
            modelArray = cfg.models;
            if isBI
                lastConfigIdxBI = cfgIdx;
            else
                lastConfigIdxIMV = cfgIdx;
            end
        else
            baseMode = ternary(isBI,'BI','IMV');
            suggestedName = sprintf('%s_index',baseMode);
            [cfgName,k,n,canceled] = askIndexParameters(10,1,suggestedName);
            if canceled || isempty(k) || isempty(n)
                return;
            end
            modelArray(1,n) = struct('struct','','S','','T','','N','','lambda',1,'w',1);
            lockedF = '';
            for j = 1:n
                if j == 1
                    inst = configureInstance( ...
                        presetStruct, presetS, presetT, presetN, ...
                        presetLam, presetW, j, n, false);
                    lockedF = inst.struct;
                else
                    inst = configureInstance( ...
                        lockedF, presetS, presetT, presetN, ...
                        presetLam, presetW, j, n, true);
                end
                modelArray(j) = inst;
            end
            cfg.name   = cfgName;
            cfg.mode   = ternary(isBI,'BI','IMV');
            cfg.k      = k;
            cfg.n      = n;
            cfg.models = modelArray;
            cfg.original = struct();
            cfg.dirty  = false;
            if isBI
                pendingConfigBI  = cfg;
                lastConfigIdxBI  = [];
            else
                pendingConfigIMV = cfg;
                lastConfigIdxIMV = [];
            end
        end
        coords = (0:k-1)/(k-1);
        [X,Y] = meshgrid(coords,coords);
        Zall = zeros(k,k,n);
        for j = 1:n
            inst = modelArray(j);
            f_j = buildHandle(inst.struct,inst.S,inst.T,inst.N,inst.lambda,inst.w);
            Zall(:,:,j) = f_j(X,Y);
        end
        BI  = (1/n) * sum(Zall,3);
        IMV = sqrt((1/n) * sum((Zall - BI).^2,3));
        if isBI
            M = BI;
            ttl = 'F.I.M. Behavior Index (BI)';
        else
            M = IMV;
            ttl = 'F.I.M. Intra-Model Variability Index (IMV)';
        end
        cla(ax);
        scatter3(ax,X(:),Y(:),M(:),36,M(:),'filled');
        xlabel(ax,'x');
        ylabel(ax,'y');
        zlabel(ax,'Index value');
        title(ax,ttl);
        colorbar(ax);
        grid(ax,'on');
        view(ax,[45 30]);
        if isIMV
            onIMVViewChanged([],[]);
        else
            axis(ax,'auto');
            daspect(ax,'auto');
        end
        set(previewTable,'Data',M.');
        [rk,ck] = size(M);
        colNames = arrayfun(@(c) sprintf('%d',c),1:ck,'UniformOutput',false);
        rowNames = arrayfun(@(r) sprintf('%d',r),1:rk,'UniformOutput',false);
        set(previewTable,'ColumnName',colNames,'RowName',rowNames);
        set(downloadBtn,'Enable','on','BackgroundColor',[0.20 0.45 0.90]);

        if useSavedCfg
            cfgCur = indexConfigs(cfgIdx);
            if isfield(cfgCur,'dirty') && cfgCur.dirty
                set(saveCfgBtn,'Enable','on','BackgroundColor',[0.20 0.45 0.90]);
            else
                set(saveCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
            end
            set(editCfgBtn,'Enable','on','BackgroundColor',[0.20 0.45 0.90]);
            set(deleteCfgBtn,'Enable','on','BackgroundColor',[0.70 0.20 0.20]);
        else
            set(saveCfgBtn,'Enable','on','BackgroundColor',[0.20 0.45 0.90]);
            set(editCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
            set(deleteCfgBtn,'Enable','off','BackgroundColor',[0.80 0.80 0.80]);
        end
    end

    % Construct function handles for S/T/N operators, including parameterized negations.
    function f = buildHandle(ss,Ss,Ts,Ns,lam,w)
        safeOps = {'\^','.^'; '(\*)','.*'; '(/)','./'};
        exprS = regexprep(regexprep(Ss,'\<x\>','u'),'\<y\>','v');
        exprT = regexprep(regexprep(Ts,'\<x\>','u'),'\<y\>','v');
        exprN = regexprep(Ns,'\<x\>','u');
        for ii=1:size(safeOps,1)
            exprS = regexprep(exprS,safeOps{ii,1},safeOps{ii,2});
            exprT = regexprep(exprT,safeOps{ii,1},safeOps{ii,2});
            exprN = regexprep(exprN,safeOps{ii,1},safeOps{ii,2});
        end
        exprN = strrep(strrep(exprN,'lambda',num2str(lam)),'w',num2str(w));
        S_h = str2func(['@(u,v)' exprS]);
        T_h = str2func(['@(u,v)' exprT]);
        N_h = str2func(['@(u)'   exprN]);
        switch ss
            case 'S(N(x),y)'
                core = @(u,v) S_h(N_h(u),v);
            case 'S(N(x),T(x,y))'
                core = @(u,v) S_h(N_h(u),T_h(u,v));
            case 'S(T(N(x),N(y)),y)'
                core = @(u,v) S_h(T_h(N_h(u),N_h(v)),v);
            case 'T(S(N(x),y),S(N(y),x))'
                core = @(u,v) T_h(S_h(N_h(u),v),S_h(N_h(v),u));
            case 'N(T(x,N(y)))'
                core = @(u,v) N_h(T_h(u,N_h(v)));
            case 'S(T(N(x),N(y)),S(T(N(x),y),T(x,y)))'
                core = @(u,v) S_h(T_h(N_h(u),N_h(v)), S_h(T_h(N_h(u),v), T_h(u,v)));
            case 'S(T(N(x),S(N(y),y)),T(x,y))'
                core = @(u,v) S_h( T_h(N_h(u), S_h(N_h(v),v) ), T_h(u,v) );
            case 'S(T(S(N(x),x),y),T(N(y),N(x)))'
                core = @(u,v) S_h( T_h(S_h(N_h(u),u),v), T_h(N_h(v),N_h(u)) );
            otherwise
                core = makeCoreFromExpr(ss,S_h,T_h,N_h);
        end
        f = @(u,v) max(min(core(u,v),1),0);
    end

    % Build a callable core from a formula string so it can be evaluated numerically.
    function core = makeCoreFromExpr(expr,S_h,T_h,N_h)
        expr = strrep(expr,' ','');

        % Recursive evaluator for custom formula strings (supports nested S/T/N, x, y).
        function val = evalCustom(exprLocal,u,v,S_hL,T_hL,N_hL)
            if startsWithLocal(exprLocal,'x')
                val = u;
                return;
            end
            if startsWithLocal(exprLocal,'y')
                val = v;
                return;
            end
            if startsWithLocal(exprLocal,'N(') && exprLocal(end)==')'
                inner = exprLocal(3:end-1);
                val = N_hL( evalCustom(inner,u,v,S_hL,T_hL,N_hL) );
                return;
            end
            if (startsWithLocal(exprLocal,'S(') || startsWithLocal(exprLocal,'T(')) && exprLocal(end)==')'
                op = exprLocal(1);
                inside = exprLocal(3:end-1);
                commaPos = splitTopComma(inside);
                left  = inside(1:commaPos-1);
                right = inside(commaPos+1:end);
                L = evalCustom(left ,u,v,S_hL,T_hL,N_hL);
                R = evalCustom(right,u,v,S_hL,T_hL,N_hL);
                if op=='S'
                    val = S_hL(L,R);
                else
                    val = T_hL(L,R);
                end
                return;
            end
            error('Unknown token in expression: %s', exprLocal);
        end

        core = @(u,v) evalCustom(expr,u,v,S_h,T_h,N_h);
    end

    % Compatibility helper for prefix checks (avoids version-dependent startsWith).
    function tf = startsWithLocal(str,pat)
        tf = strncmp(str,pat,length(pat));
    end

    % Locate the top-level comma in a formula while respecting nested parentheses.
    function pos = splitTopComma(s)
        depth = 0;
        pos = 0;
        for i = 1:length(s)
            c = s(i);
            if c == '('
                depth = depth + 1;
            elseif c == ')'
                depth = depth - 1;
            elseif (c == ',') && (depth == 0)
                pos = i;
                return;
            end
        end
        error('Comma not found in segment: %s', s);
    end

    function [name,k,n,canceled] = askIndexParameters(defaultK,defaultN,defaultName)
        name = '';
        k = [];
        n = [];
        canceled = false;
        dlgW = 500;
        dlgH = 240;
        d = dialog('Name','Index Configuration', ...
            'Position',[0 0 dlgW dlgH], ...
            'WindowStyle','modal','Color',dialogBG);
        centerDialog(d,fig);
        lw = 150;
        gap = 14;
        cw = 230;
        groupW = lw + gap + cw;
        lx = (dlgW - groupW)/2;
        cx = lx + lw + gap;
        rowGap = 40;
        blockH = 2*rowGap + 25; % 3 rows of height 25 separated by rowGap
        yName = (dlgH + blockH)/2 - 25;
        yK = yName - rowGap;
        yN = yK - rowGap;
        uicontrol(d,'Style','text','String','Configuration Name:', ...
            'Position',[lx yName lw 25], ...
            'HorizontalAlignment','right', ...
            'BackgroundColor',dialogBG,'FontWeight','bold');
        edName = uicontrol(d,'Style','edit','String',defaultName, ...
            'Position',[cx yName cw 25], ...
            'BackgroundColor',dialogBG, ...
            'HorizontalAlignment','left');
        uicontrol(d,'Style','text','String','Index Depth k (>1):', ...
            'Position',[lx yK lw 25], ...
            'HorizontalAlignment','right', ...
            'BackgroundColor',dialogBG,'FontWeight','bold');
        edK = uicontrol(d,'Style','edit','String',num2str(defaultK), ...
            'Position',[cx yK cw 25], ...
            'BackgroundColor',dialogBG, ...
            'HorizontalAlignment','left');
        uicontrol(d,'Style','text','String','Index Degree n (>=1):', ...
            'Position',[lx yN lw 25], ...
            'HorizontalAlignment','right', ...
            'BackgroundColor',dialogBG,'FontWeight','bold');
        edN = uicontrol(d,'Style','edit','String',num2str(defaultN), ...
            'Position',[cx yN cw 25], ...
            'BackgroundColor',dialogBG, ...
            'HorizontalAlignment','left');
        btnY = 20;
        btnW = 90;
        btnH = 30;
        gapBtn = 40;
        xOK     = dlgW/2 - btnW - gapBtn/2;
        xCancel = dlgW/2 + gapBtn/2;
        uicontrol(d,'Style','pushbutton','String','OK', ...
            'Position',[xOK btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90], ...
            'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) onOK());
        uicontrol(d,'Style','pushbutton','String','Cancel', ...
            'Position',[xCancel btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.92 0.92 0.92], ...
            'Callback',@(~,~) onCancel());
        set(d,'WindowKeyPressFcn',@onKey);
        uiwait(d);
        if ishghandle(d)
            delete(d);
        end
        % Accept dialog inputs and continue execution with the provided values.
        function onOK()
            nm = strtrim(get(edName,'String'));
            if isempty(nm)
                nm = defaultName;
            end
            kVal = str2double(get(edK,'String'));
            nVal = str2double(get(edN,'String'));
            if isnan(kVal) || kVal <= 1 || isnan(nVal) || nVal < 1
                h = warndlg('Please Enter k>1 and n>=1.','Invalid parameters');
                attachEnterClose(h);
                return;
            end
            name = nm;
            k = max(2,round(kVal));
            n = max(1,round(nVal));
            uiresume(d);
        end
        % Cancel the dialog and signal that no values should be applied.
        function onCancel()
            canceled = true;
            name = '';
            k = [];
            n = [];
            uiresume(d);
        end
        % Local dialog key handler for Enter/Escape shortcuts.
        function onKey(~,evt)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                onOK();
            elseif strcmp(evt.Key,'escape')
                onCancel();
            end
        end
    end

    % Dialog to configure a single F.I.M. instance (structure, operators, parameters).
    function inst = configureInstance(defStruct,defS,defT,defN,defLam,defW,idx,total,lockStruct)
        dlgW = 520;
        rows = 6;
        h = 25;
        sp = 60;
        bg = 130;
        dlgH = sp*(rows-1) + h + bg;
        d = dialog('Name',sprintf('Instance %d of %d',idx,total), ...
            'Position',[0 0 dlgW dlgH],'WindowStyle','modal','Color',dialogBG);
        centerDialog(d,fig);
        set(d,'WindowKeyPressFcn',@(~,e) onKey(e,d));
        % Center the 6-row form block vertically and horizontally
        blockH = (rows-1)*sp + h;
        topY = (dlgH + blockH)/2 - h;   % y of first row
        Ys   = topY - (0:rows-1)*sp;    % y for each row center
        gap = 18;
        lw  = 150;
        cw  = 230;
        groupW = lw + gap + cw;
        lx = (dlgW - groupW)/2;
        cx = lx + lw + gap;
        uicontrol(d,'Style','text','String','F.I.M.:','Position',[lx Ys(1) lw h], ...
            'HorizontalAlignment','right','BackgroundColor',dialogBG);
        structList = structPopup.String;
        if ischar(structList)
            structList = cellstr(structList);
        end
        iS = find(strcmp(defStruct,structList),1);
        if isempty(iS)
            iS = 1;
        end
        enStr = 'on';
        if lockStruct
            enStr = 'off';
        end
        dd1 = uicontrol(d,'Style','popupmenu','String',structList, ...
            'Position',[cx Ys(1) cw h], 'Value',iS, 'Enable',enStr);
        uicontrol(d,'Style','text','String','Disjunction S(x,y):','Position',[lx Ys(2) lw h], ...
            'HorizontalAlignment','right','BackgroundColor',dialogBG);
        dd2 = uicontrol(d,'Style','popupmenu','String',itemsS, ...
            'Position',[cx Ys(2) cw h], 'Value',find(strcmp(defS,itemsS),1));
        uicontrol(d,'Style','text','String','Conjunction T(x,y):','Position',[lx Ys(3) lw h], ...
            'HorizontalAlignment','right','BackgroundColor',dialogBG);
        dd3 = uicontrol(d,'Style','popupmenu','String',itemsT, ...
            'Position',[cx Ys(3) cw h], 'Value',find(strcmp(defT,itemsT),1));
        uicontrol(d,'Style','text','String','Negation N(x):','Position',[lx Ys(4) lw h], ...
            'HorizontalAlignment','right','BackgroundColor',dialogBG);
        dd4 = uicontrol(d,'Style','popupmenu','String',itemsN, ...
            'Position',[cx Ys(4) cw h], 'Value',find(strcmp(defN,itemsN),1));
        uicontrol(d,'Style','text','String','λ Parameter:','Position',[lx Ys(5) lw h], ...
            'HorizontalAlignment','right','BackgroundColor',dialogBG);
        edL = uicontrol(d,'Style','edit','String',num2str(defLam), ...
            'Position',[cx Ys(5) cw h], 'BackgroundColor',dialogBG);
        uicontrol(d,'Style','text','String','w Parameter:','Position',[lx Ys(6) lw h], ...
            'HorizontalAlignment','right','BackgroundColor',dialogBG);
        edW = uicontrol(d,'Style','edit','String',num2str(defW), ...
            'Position',[cx Ys(6) cw h], 'BackgroundColor',dialogBG);
        uicontrol(d,'Style','pushbutton','String','OK', ...
            'Position',[(dlgW-120)/2,12,120,32], 'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90],'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) uiresume(d));
        uiwait(d);
        inst.struct = structList{dd1.Value};
        inst.S      = itemsS{dd2.Value};
        inst.T      = itemsT{dd3.Value};
        inst.N      = itemsN{dd4.Value};
        inst.lambda = str2double(edL.String);
        inst.w      = str2double(edW.String);
        delete(d);
        % Local dialog key handler for Enter/Escape shortcuts.
        function onKey(evt,dlgHandle)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                uiresume(dlgHandle);
            end
        end
    end

    % Parse a formula string into a node tree suitable for the designer view.
    function idx = buildTreeFromExpr(expr)
        expr = strrep(expr,' ','');
        if isempty(nodes)
            nodes = struct('type',{},'left',{},'right',{});
        end
        % Allocate a new node index in the tree and return its position.
        function k = newNodeIndex()
            if isempty(nodes)
                k = 1;
                nodes(1).type  = 'o';
                nodes(1).left  = 0;
                nodes(1).right = 0;
            else
                k = numel(nodes) + 1;
                nodes(k).type  = 'o';
                nodes(k).left  = 0;
                nodes(k).right = 0;
            end
        end
        if strcmp(expr,'x') || strcmp(expr,'y')
            idx = newNodeIndex();
            nodes(idx).type  = expr;
            nodes(idx).left  = 0;
            nodes(idx).right = 0;
            return;
        end
        if startsWithLocal(expr,'N(') && expr(end)==')'
            inner = expr(3:end-1);
            idx = newNodeIndex();
            nodes(idx).type  = 'N';
            nodes(idx).right = 0;
            leftIdx = buildTreeFromExpr(inner);
            nodes(idx).left  = leftIdx;
            return;
        end
        if (startsWithLocal(expr,'S(') || startsWithLocal(expr,'T(')) && expr(end)==')'
            op = expr(1);
            inside = expr(3:end-1);
            commaPos = splitTopComma(inside);
            leftStr  = inside(1:commaPos-1);
            rightStr = inside(commaPos+1:end);
            idx = newNodeIndex();
            nodes(idx).type = op;
            leftIdx  = buildTreeFromExpr(leftStr);
            rightIdx = buildTreeFromExpr(rightStr);
            nodes(idx).left  = leftIdx;
            nodes(idx).right = rightIdx;
            return;
        end
        error('Cannot parse expression: %s',expr);
    end

    % Dialog to select and load a stored F.I.M. formula into the designer.
    function loadFIMFromList()
        cur = structPopup.String;
        if ischar(cur)
            cur = cellstr(cur);
        end
        if isempty(cur)
            h = warndlg('No F.I.M. Structures Available to Load.','Load F.I.M.');
            attachEnterClose(h);
            figure(fig);
            return;
        end
        dlgW = 420;
        dlgH = 320;
        d = dialog('Name','Load F.I.M. into the Designer', ...
            'Position',[0 0 dlgW dlgH], ...
            'WindowStyle','modal', ...
            'Color',dialogBG);
        centerDialog(d,fig);
        uicontrol(d,'Style','text', ...
            'String','Select a F.I.M. Formula:', ...
            'Position',[20 dlgH-60 dlgW-40 30], ...
            'HorizontalAlignment','center', ...
            'BackgroundColor',dialogBG, ...
            'FontWeight','bold');
        lb = uicontrol(d,'Style','listbox', ...
            'String',cur, ...
            'Value',structPopup.Value, ...
            'Position',[20 70 dlgW-40 dlgH-140], ...
            'BackgroundColor',dialogBG, ...
            'Max',1,'Min',1);
        selectedIndex = [];
        uicontrol(d,'Style','pushbutton','String','OK', ...
            'Position',[dlgW/2-110 20 100 30], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90], ...
            'ForegroundColor',[1 1 1], ...
            'Callback',@onOK);
        uicontrol(d,'Style','pushbutton','String','Cancel', ...
            'Position',[dlgW/2+10 20 100 30], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.92 0.92 0.92], ...
            'Callback',@onCancel);
        set(d,'WindowKeyPressFcn',@onKeyPress);
        uiwait(d);
        if isempty(selectedIndex)
            if ishghandle(d)
                delete(d);
            end
            figure(fig);
            return;
        end
        expr = cur{selectedIndex};
        if ishghandle(d)
            delete(d);
        end
        try
            nodes = struct('type',{},'left',{},'right',{});
            buildTreeFromExpr(expr);
            selectedNode = 1;
            renderPuzzle();
            updateExprText();
            h = msgbox(sprintf('Loaded F.I.M.:\n%s',expr), ...
                'F.I.M. Loaded','help');
            attachEnterClose(h);
        catch ME
            h = errordlg(sprintf('Could not load F.I.M. expression:\n%s\n\nError: %s', ...
                expr, ME.message), ...
                'Load F.I.M. error');
            attachEnterClose(h);
        end
        figure(fig);
        % Accept dialog inputs and continue execution with the provided values.
        function onOK(~,~)
            selectedIndex = lb.Value;
            uiresume(d);
        end
        % Cancel the dialog and signal that no values should be applied.
        function onCancel(~,~)
            selectedIndex = [];
            uiresume(d);
        end
        % Dialog key handler to trigger OK/Cancel via Enter/Escape.
        function onKeyPress(~,evt)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                onOK([],[]);
            elseif strcmp(evt.Key,'escape')
                onCancel([],[]);
            end
        end
    end

    % Initialize or reset the designer tree to a blank root node.
    function initPuzzle()
        nodes = struct('type','o','left',0,'right',0);
        selectedNode = 1;
        renderPuzzle();
        updateExprText();
    end

    % Insert the selected operator/operand into the current node and refresh the view.
    function addPiece(kind)
        if selectedNode < 1 || selectedNode > numel(nodes)
            return;
        end
        oldLeft  = nodes(selectedNode).left;
        oldRight = nodes(selectedNode).right;
        placeholder = struct('type','o','left',0,'right',0);
        nodes(selectedNode).type = kind;
        switch kind
            case {'S','T'}
                if oldLeft == 0
                    nodes(end+1) = placeholder;
                    nodes(selectedNode).left = numel(nodes);
                else
                    nodes(selectedNode).left = oldLeft;
                end
                if oldRight == 0
                    nodes(end+1) = placeholder;
                    nodes(selectedNode).right = numel(nodes);
                else
                    nodes(selectedNode).right = oldRight;
                end
            case 'N'
                if oldLeft == 0
                    nodes(end+1) = placeholder;
                    nodes(selectedNode).left = numel(nodes);
                else
                    nodes(selectedNode).left = oldLeft;
                end
                nodes(selectedNode).right = 0;
            otherwise
                nodes(selectedNode).left  = 0;
                nodes(selectedNode).right = 0;
        end
        renderPuzzle();
        updateExprText();
    end

    % Clear the selected node and all of its descendants.
    function clearSubtree()
        if selectedNode < 1 || selectedNode > numel(nodes)
            return;
        end
        nodes(selectedNode).type  = 'o';
        nodes(selectedNode).left  = 0;
        nodes(selectedNode).right = 0;
        renderPuzzle();
        updateExprText();
    end

    % Return true only if the tree has no empty slots (i.e., a complete formula).
    function tf = isComplete(idx)
        if idx==0
            tf = false;
            return;
        end
        t = nodes(idx).type;
        switch t
            case {'x','y'}
                tf = true;
            case 'N'
                tf = (nodes(idx).left~=0) && isComplete(nodes(idx).left);
            case {'S','T'}
                tf = (nodes(idx).left~=0) && (nodes(idx).right~=0) && ...
                    isComplete(nodes(idx).left) && isComplete(nodes(idx).right);
            otherwise
                tf = false;
        end
    end

    % Serialize the current tree back into a readable formula string.
    function s = exprString(idx)
        if idx==0
            s = 'o';
            return;
        end
        t = nodes(idx).type;
        switch t
            case 'x'
                s = 'x';
            case 'y'
                s = 'y';
            case 'N'
                s = ['N(' exprString(nodes(idx).left) ')'];
            case 'S'
                s = ['S(' exprString(nodes(idx).left) ',' exprString(nodes(idx).right) ')'];
            case 'T'
                s = ['T(' exprString(nodes(idx).left) ',' exprString(nodes(idx).right) ')'];
            otherwise
                s = 'o';
        end
    end

    % Update the large formula preview text in designer mode.
    function updateExprText()
        if isempty(nodes)
            e = '(empty)';
        else
            e = exprString(1);
        end
        set(bigExprText,'String',e);
    end

    % Layout and draw the current formula tree in the designer axes.
    function renderPuzzle()
        cla(axBuild);
        hold(axBuild,'on');
        axis(axBuild,[0 1 0 1]);
        axis(axBuild,'off');
        Nn = numel(nodes);
        if Nn==0
            return;
        end
        xPos    = nan(1,Nn);
        depthLv = nan(1,Nn);
        % Compute subtree width for balanced layout spacing.
        function w = subWidth(i)
            if i==0
                w = 0;
                return;
            end
            switch nodes(i).type
                case {'x','y','o'}
                    w = 1;
                case 'N'
                    w = max(1, subWidth(nodes(i).left));
                case {'S','T'}
                    w = max(1, subWidth(nodes(i).left) + subWidth(nodes(i).right));
                otherwise
                    w = 1;
            end
        end
        % Recursively assign node positions based on subtree widths and depth.
        function assign(i, xCenter, span, depth)
            if i==0
                return;
            end
            xPos(i)    = xCenter;
            depthLv(i) = depth;
            switch nodes(i).type
                case {'x','y','o'}
                case 'N'
                    assign(nodes(i).left, xCenter, max(0.4,0.6*span), depth+1);
                case {'S','T'}
                    wL = subWidth(nodes(i).left);
                    wR = subWidth(nodes(i).right);
                    tot = max(1, wL + wR);
                    leftSpan  = max(0.4*span*double(wL>0), span * (wL/tot));
                    rightSpan = max(0.4*span*double(wR>0), span * (wR/tot));
                    assign(nodes(i).left , xCenter - span/2 + leftSpan/2 , leftSpan , depth+1);
                    assign(nodes(i).right, xCenter + span/2 - rightSpan/2, rightSpan, depth+1);
            end
        end
        assign(1, 0.5, 0.9, 1);
        valid = ~isnan(depthLv);
        if any(valid)
            maxDepth = max(depthLv(valid));
        else
            maxDepth = 1;
        end
        for i=1:Nn
            if isnan(xPos(i))
                continue;
            end
            p = [xPos(i), 1 - (depthLv(i)/(maxDepth+1)) - 0.05];
            if nodes(i).left~=0 && ~isnan(xPos(nodes(i).left))
                c = [xPos(nodes(i).left), 1 - (depthLv(nodes(i).left)/(maxDepth+1)) - 0.05];
                plot(axBuild,[p(1) c(1)],[p(2)-0.02 c(2)+0.02],'-','LineWidth',1,'Color',[0.6 0.7 0.9]);
            end
            if nodes(i).right~=0 && ~isnan(xPos(nodes(i).right))
                c = [xPos(nodes(i).right), 1 - (depthLv(nodes(i).right)/(maxDepth+1)) - 0.05];
                plot(axBuild,[p(1) c(1)],[p(2)-0.02 c(2)+0.02],'-','LineWidth',1,'Color',[0.6 0.7 0.9]);
            end
        end
        % Select a node in the tree and redraw to update highlighting.
        function selectNode(iSel)
            selectedNode = iSel;
            renderPuzzle();
        end
        for i=1:Nn
            if isnan(xPos(i))
                continue;
            end
            x = xPos(i);
            y = 1 - (depthLv(i)/(maxDepth+1)) - 0.05;
            drawNode(i,x,y);
        end
        % Render a single node with type-specific colors and selection styling.
        function drawNode(i,x,y)
            t = nodes(i).type;
            w = 0.10;
            h = 0.06;
            isSel = (i == selectedNode);
            if t=='S'
                face = [0.85 0.93 1.00];
            elseif t=='T'
                face = [0.88 1.00 0.88];
            elseif t=='N'
                face = [1.00 0.95 0.85];
            elseif t=='x'
                face = [0.90 0.92 1.00];
            elseif t=='y'
                face = [1.00 0.92 0.96];
            else
                face = [0.98 0.98 0.98];
            end
            if isSel
                ec = [0.10 0.45 0.90];
                lw = 2;
            else
                ec = [0.5 0.5 0.5];
                lw = 1;
            end
            rectangle(axBuild,'Position',[x-w/2 y-h/2 w h], ...
                'Curvature',0.25, 'LineWidth', lw, ...
                'EdgeColor', ec, 'FaceColor', face, ...
                'HitTest','on','ButtonDownFcn',@(~,~) selectNode(i));
            text(axBuild, x, y, t, 'HorizontalAlignment','center','VerticalAlignment','middle', ...
                'FontWeight','bold','Color',[0.1 0.1 0.1],'HitTest','on', ...
                'ButtonDownFcn',@(~,~) selectNode(i));
        end
    end

    % Evaluate the current tree numerically for inputs (u, v) using S/T/N handles.
    function Z = evalTree(idx,u,v,S_h,T_h,N_h)
        t = nodes(idx).type;
        switch t
            case 'x'
                Z = u;
            case 'y'
                Z = v;
            case 'N'
                Z = N_h( evalTree(nodes(idx).left,u,v,S_h,T_h,N_h) );
            case 'S'
                L = evalTree(nodes(idx).left ,u,v,S_h,T_h,N_h);
                R = evalTree(nodes(idx).right,u,v,S_h,T_h,N_h);
                Z = S_h(L,R);
            case 'T'
                L = evalTree(nodes(idx).left ,u,v,S_h,T_h,N_h);
                R = evalTree(nodes(idx).right,u,v,S_h,T_h,N_h);
                Z = T_h(L,R);
            otherwise
                error('Encountered empty slot during evaluation.');
        end
    end

    % Check whether the current formula already exists in session or persistent storage.
    function onDuplicateCheck()
        if ~isComplete(1)
            h = warndlg('Your Composition has Empty Slots. Complete it First.','Incomplete');
            attachEnterClose(h);
            return;
        end
        expr = exprString(1);
        cur = structPopup.String;
        if ischar(cur)
            cur = cellstr(cur);
        end
        inSession  = any(strcmp(cur,expr));
        persisted  = loadPersistentFIMs();
        inPersist  = any(strcmp(persisted,expr));
        if inSession || inPersist
            msg = 'This Composition Already Exists in the F.I.M. List.';
            if inPersist
                msg = [msg ' (Saved permanently)'];
            else
                msg = [msg ' (Saved in this session)'];
            end
            h = helpdlg(msg,'Duplicate F.I.M. Check');
            attachEnterClose(h);
        else
            h = helpdlg('No Duplicate of Your Formula Found! You Can Add It to the List...', ...
                'Duplicate F.I.M. Check');
            attachEnterClose(h);
        end
    end

    % Add the current formula to the list and optionally persist it across sessions.
    function addCurrentToFIM()
        if ~isComplete(1)
            h = warndlg('Your Composition has Empty Slots. Complete it First.','Incomplete');
            attachEnterClose(h);
            return;
        end
        expr = exprString(1);
        cur = structPopup.String;
        if ischar(cur)
            cur = cellstr(cur);
        end
        if any(strcmp(cur,expr))
            h = warndlg('This Composition Already Exists in the F.I.M. list.','Duplicate');
            attachEnterClose(h);
            return;
        end
        cur{end+1} = expr;
        structPopup.String = cur;
        structPopup.Value  = numel(cur);
        choice = yesNoDialog('Composition Added. Make it Permanent and for Future Sessions?', ...
            'Persist F.I.M.','Yes');
        if strcmp(choice,'Yes')
            if savePersistentFIM(expr)
                h = msgbox('Saved Permanently.', ...
                    'Saved','help');
                attachEnterClose(h);
            else
                h = warndlg('It is Already Permanently Saved.','Already Saved');
                attachEnterClose(h);
            end
        end
    end

    % Reusable Yes/No modal dialog with configurable default behavior.
    function choice = yesNoDialog(question,title,defaultBtn)
        choice = 'No';
        if nargin < 3
            defaultBtn = 'Yes';
        end
        dlgW = 420;
        dlgH = 160;
        d = dialog('Name',title, ...
            'Position',[0 0 dlgW dlgH], ...
            'WindowStyle','modal','Color',dialogBG);
        centerDialog(d,fig);
        set(d,'WindowKeyPressFcn',@onKey);
        uicontrol(d,'Style','text','String',question, ...
            'Position',[20 (dlgH-60)/2 dlgW-40 60], ...
            'BackgroundColor',dialogBG, ...
            'HorizontalAlignment','center','FontWeight','bold');
        btnY = 25;
        btnW = 90;
        btnH = 30;
        yesX = dlgW/2 - btnW - 10;
        noX  = dlgW/2 + 10;
        uicontrol(d,'Style','pushbutton','String','Yes', ...
            'Position',[yesX btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.20 0.45 0.90], ...
            'ForegroundColor',[1 1 1], ...
            'Callback',@(~,~) onChoice('Yes'));
        uicontrol(d,'Style','pushbutton','String','No', ...
            'Position',[noX btnY btnW btnH], ...
            'FontWeight','bold', ...
            'BackgroundColor',[0.92 0.92 0.92], ...
            'Callback',@(~,~) onChoice('No'));
        uiwait(d);
        if ishghandle(d)
            delete(d);
        end
        % Local dialog callback to capture the user's selection and resume execution.
        function onChoice(c)
            choice = c;
            uiresume(d);
        end
        % Local dialog key handler for Enter/Escape shortcuts.
        function onKey(~,evt)
            if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter')
                onChoice(defaultBtn);
            elseif strcmp(evt.Key,'escape')
                onChoice('No');
            end
        end
    end

    % Rebuild the configuration dropdown, preserving selection and dirty markers.
    function rebuildConfigPopup(selectedName)
        if nargin<1
            selectedName = '';
        end
        oldName = '';
        strsOld = get(configPopup,'String');
        if ~iscell(strsOld)
            strsOld = cellstr(strsOld);
        end
        curVal = get(configPopup,'Value');
        if ~isempty(strsOld) && curVal>=1 && curVal<=numel(strsOld)
            if curVal>1
                oldName = stripStar(strsOld{curVal});
            end
        end
        namesDisplay = cell(1,numel(indexConfigs));
        for i=1:numel(indexConfigs)
            nm = indexConfigs(i).name;
            if isfield(indexConfigs(i),'dirty') && indexConfigs(i).dirty
                nmDisp = [nm '*'];
            else
                nmDisp = nm;
            end
            namesDisplay{i} = nmDisp;
        end
        strs = [{'New Configuration'} namesDisplay];
        set(configPopup,'String',strs);
        if ~isempty(selectedName)
            targetName = selectedName;
        else
            targetName = oldName;
        end
        if ~isempty(targetName)
            val = find(strcmp(strs,targetName) | strcmp(strs,[targetName '*']),1);
            if ~isempty(val)
                set(configPopup,'Value',val);
            else
                set(configPopup,'Value',1);
            end
        else
            set(configPopup,'Value',1);
        end
        onConfigSelection([],[]);
    end

    % Remove a trailing '*' marker from configuration names (dirty indicator).
    function base = stripStar(name)
        base = name;
        if ~isempty(base) && base(end)=='*'
            base = base(1:end-1);
        end
    end

    % Add a configuration to the in-memory registry and refresh the dropdown list.
    function idx = registerConfig(cfg)
        if ~isfield(cfg,'name') || isempty(cfg.name)
            cfg.name = sprintf('%s_config_%d', cfg.mode, numel(indexConfigs)+1);
        end
        if ~isfield(cfg,'original') || isempty(cfg.original)
            cfg.original.name   = cfg.name;
            cfg.original.k      = cfg.k;
            cfg.original.n      = cfg.n;
            cfg.original.models = cfg.models;
        end
        cfg.dirty = false;
        if isempty(indexConfigs)
            indexConfigs = cfg;
            idx = 1;
        else
            indexConfigs(end+1) = cfg;
            idx = numel(indexConfigs);
        end
        rebuildConfigPopup(cfg.name);
    end

    % Small utility that returns a or b depending on the boolean condition.
    function out = ternary(cond,a,b)
        if cond
            out = a;
        else
            out = b;
        end
    end

    % Generate a non-colliding configuration name using numeric suffixes when needed.
    function nm = uniqueConfigName(baseName, idxExclude)
        if nargin < 2
            idxExclude = [];
        end
        existing = {indexConfigs.name};
        % Optionally ignore one entry (e.g., when we're renaming that same entry).
        if ~isempty(idxExclude) && idxExclude >= 1 && idxExclude <= numel(existing)
            existing(idxExclude) = [];
        end

        % If the proposed name is unused, keep it as-is.
        if ~any(strcmp(existing, baseName))
            nm = baseName;
            return;
        end

        % Normalize to base root (strip a trailing numeric suffix if present),
        % then choose the next available integer suffix across all variants.
        baseRoot = stripNumericSuffix(baseName);
        escapedRoot = regexptranslate('escape', baseRoot);
        maxSuffix = 1; % root without suffix counts as 1
        for ii = 1:numel(existing)
            cand = existing{ii};
            if strcmp(cand, baseRoot)
                maxSuffix = max(maxSuffix, 1);
                continue;
            end
            tok = regexp(cand, ['^' escapedRoot ' \((\d+)\)$'], 'tokens', 'once');
            if ~isempty(tok)
                nVal = str2double(tok{1});
                if ~isnan(nVal)
                    maxSuffix = max(maxSuffix, nVal);
                end
            end
        end
        nm = sprintf('%s (%d)', baseRoot, maxSuffix + 1);

        % Helper to remove a trailing numeric suffix of the form ' (n)'.
        function root = stripNumericSuffix(nameIn)
            tok = regexp(nameIn, '^(.*)\s\(\d+\)$', 'tokens', 'once');
            if isempty(tok)
                root = nameIn;
            else
                root = strtrim(tok{1});
            end
        end
    end

    % Append persisted formulas to the session list while honoring exclusions.
    function appendPersistentFIMs()
        list = loadPersistentFIMs();
        if isempty(list)
            return;
        end
        removeSet = {'S(N(x),T(x,y))','S(T(N(x),N(y)),y)', ...
            'T(S(N(x),y),S(N(y),x))','N(T(x,N(y)))'};
        cur = structPopup.String;
        if ischar(cur)
            cur = cellstr(cur);
        end
        for iList = 1:numel(list)
            ex = list{iList};
            if any(strcmp(removeSet,ex))
                continue;
            end
            if ~any(strcmp(cur,ex))
                cur{end+1} = ex;
            end
        end
        structPopup.String = cur;
    end

    % Persist a new formula and current configuration list to the MAT-file.
    function ok = savePersistentFIM(expr)
        [persistFile, ~] = persistInfo();
        ok = false;
        fim_list = loadPersistentFIMs();
        if any(strcmp(fim_list,expr))
            return;
        end
        fim_list{end+1} = expr;
        index_configs = buildIndexConfigsForSave();
        try
            save(persistFile, 'fim_list','index_configs','-mat');
            ok = true;
        catch
            ok = false;
        end
    end

    % Load persisted formulas from disk and remove excluded items.
    function list = loadPersistentFIMs()
        [persistFile, ~] = persistInfo();
        list = {};
        if exist(persistFile,'file')
            S = load(persistFile, 'fim_list');
            if isfield(S,'fim_list')
                list = S.fim_list;
            end
        end
        if isempty(list)
            return;
        end
        removeSet = {'S(N(x),T(x,y))','S(T(N(x),N(y)),y)', ...
            'T(S(N(x),y),S(N(y),x))','N(T(x,N(y)))'};
        keepMask = true(size(list));
        for i=1:numel(list)
            if any(strcmp(removeSet,list{i}))
                keepMask(i) = false;
            end
        end
        list = list(keepMask);
    end

    % Load persisted index configurations into runtime structures.
    function cfgs = loadPersistentConfigs()
        [persistFile, ~] = persistInfo();
        cfgs = struct('name',{},'mode',{},'k',{},'n',{},'models',{}, ...
            'original',{},'dirty',{});
        if exist(persistFile,'file')
            S = load(persistFile, 'index_configs');
            if isfield(S,'index_configs')
                baseCfgs = S.index_configs;
                if ~isempty(baseCfgs)
                    cfgs = repmat(struct('name','','mode','','k',0,'n',0,'models',[], ...
                        'original',struct(),'dirty',false), ...
                        1,numel(baseCfgs));
                    for i=1:numel(baseCfgs)
                        cfgs(i).name   = baseCfgs(i).name;
                        cfgs(i).mode   = baseCfgs(i).mode;
                        cfgs(i).k      = baseCfgs(i).k;
                        cfgs(i).n      = baseCfgs(i).n;
                        cfgs(i).models = baseCfgs(i).models;
                        cfgs(i).original.name   = baseCfgs(i).name;
                        cfgs(i).original.k      = baseCfgs(i).k;
                        cfgs(i).original.n      = baseCfgs(i).n;
                        cfgs(i).original.models = baseCfgs(i).models;
                        cfgs(i).dirty = false;
                    end
                end
            end
        end
    end

    % Build a save-ready configuration struct array from in-memory entries.
    function index_configs = buildIndexConfigsForSave()
        index_configs = struct('name',{},'mode',{},'k',{},'n',{},'models',{});
        if isempty(indexConfigs)
            return;
        end
        index_configs(1,numel(indexConfigs)) = struct('name','','mode','','k',0,'n',0,'models',[]);
        for i=1:numel(indexConfigs)
            cfg = indexConfigs(i);
            if isfield(cfg,'original') && ~isempty(cfg.original)
                base = cfg.original;
            else
                base.name   = cfg.name;
                base.k      = cfg.k;
                base.n      = cfg.n;
                base.models = cfg.models;
            end
            index_configs(i).name   = base.name;
            index_configs(i).mode   = cfg.mode;
            index_configs(i).k      = base.k;
            index_configs(i).n      = base.n;
            index_configs(i).models = base.models;
        end
    end

    % Persist the configuration list to the MAT-file alongside formulas.
    function savePersistentConfigs()
        [persistFile, ~] = persistInfo();
        fim_list = loadPersistentFIMs();
        index_configs = buildIndexConfigsForSave();
        try
            save(persistFile,'fim_list','index_configs','-mat');
        catch
        end
    end

    function [filePath, varName] = persistInfo()
        fn = mfilename('fullpath');
        if isempty(fn)
            baseDir = pwd;
        else
            baseDir = fileparts(fn);
        end
        filePath = fullfile(baseDir,'FoFIMT_Saved_Inputs.mat');
        varName  = 'fim_list';
    end

    % Keyboard navigation and shortcuts for the designer mode tree editor.
    function onMainKeyPress(~,evt)
        if modePopup.Value ~= 4
            return;
        end
        if isempty(nodes) || selectedNode < 1 || selectedNode > numel(nodes)
            return;
        end
        key = evt.Key;
        switch key
            case 'leftarrow'
                if nodes(selectedNode).left ~= 0
                    selectedNode = nodes(selectedNode).left;
                    renderPuzzle();
                end
            case 'rightarrow'
                if nodes(selectedNode).right ~= 0
                    selectedNode = nodes(selectedNode).right;
                    renderPuzzle();
                end
            case 'uparrow'
                p = findParentNode(selectedNode);
                if p ~= 0
                    selectedNode = p;
                    renderPuzzle();
                end
            case 'downarrow'
                if nodes(selectedNode).left ~= 0
                    selectedNode = nodes(selectedNode).left;
                    renderPuzzle();
                elseif nodes(selectedNode).right ~= 0
                    selectedNode = nodes(selectedNode).right;
                    renderPuzzle();
                end
            otherwise
                ch = lower(key);
                switch ch
                    case 'x'
                        addPiece('x');
                    case 'y'
                        addPiece('y');
                    case 'n'
                        addPiece('N');
                    case 's'
                        addPiece('S');
                    case 't'
                        addPiece('T');
                end
        end
    end

    % Locate the parent of a given node index in the tree.
    function p = findParentNode(childIdx)
        p = 0;
        for ii = 1:numel(nodes)
            if nodes(ii).left == childIdx || nodes(ii).right == childIdx
                p = ii;
                return;
            end
        end
    end

    % Attach enter/escape key handling to close a dialog.
    function attachEnterClose(figHandle)
        if ishghandle(figHandle)
            centerPopup(figHandle);
            set(figHandle,'WindowKeyPressFcn',@onPopupKey);
        end
    end

    % Close dialog on Enter or Escape key press.
    function onPopupKey(src,evt)
        if strcmp(evt.Key,'return') || strcmp(evt.Key,'enter') || strcmp(evt.Key,'escape')
            if ishghandle(src)
                delete(src);
            end
        end
    end

    % Center a dialog relative to the main figure.
    function centerPopup(h)
        if ishghandle(h)
            centerDialog(h,fig);
        end
    end

    % Compute and set dialog position relative to parent figure or screen.
    function centerDialog(dlg,parentFig)
        if ~ishghandle(dlg)
            return;
        end
        scr2 = get(0,'ScreenSize');
        dlgPos = get(dlg,'Position');
        if nargin > 1 && ishghandle(parentFig)
            parentPos = get(parentFig,'Position');
            newX = parentPos(1) + (parentPos(3)-dlgPos(3))/2;
            newY = parentPos(2) + (parentPos(4)-dlgPos(4))/2;
        else
            newX = scr2(1) + (scr2(3)-dlgPos(3))/2;
            newY = scr2(2) + (scr2(4)-dlgPos(4))/2;
        end
        set(dlg,'Position',[newX newY dlgPos(3) dlgPos(4)]);
    end

    % Convenience helper for setting the Visible property on an array of handles.
    function setVisible(h, tf)
        vis = onOff(tf);
        for ii = 1:numel(h)
            try
                set(h(ii),'Visible',vis);
            catch
            end
        end
    end

    % Convert a logical flag into MATLAB 'on'/'off' strings.
    function s = onOff(tf)
        if tf
            s = 'on';
        else
            s = 'off';
        end
    end
end
