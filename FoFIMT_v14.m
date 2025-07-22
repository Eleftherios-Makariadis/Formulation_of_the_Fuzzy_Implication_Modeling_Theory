function FoFIMT_v14
    % ---- Main UI ----
    fig = figure('Name','FoFIMT_v14','NumberTitle','off','Position',[200 200 1000 600]);
    ax  = axes(fig,'Units','normalized','Position',[0.55 0.10 0.40 0.85]);
    view(ax,[45 30]); grid(ax,'on');

    % Mode selector
    uicontrol(fig,'Style','text','String','Program Mode:','Units','normalized', ...
              'Position',[0.05 0.90 0.1 0.05],'HorizontalAlignment','left');
    modePopup = uicontrol(fig,'Style','popupmenu', ...
        'String',{'Single F.I.M. Instance','Behavior Index (BI)','Intra-Model Variability Index (IMV)'}, ...
        'Units','normalized','Position',[0.15 0.90 0.3 0.05], ...
        'Callback',@modeChanged);

    % --- Single-instance controls ---
    lblStruct   = uicontrol(fig,'Style','text','String','F.I.M.:','Units','normalized', ...
                            'Position',[0.05 0.82 0.1 0.05],'HorizontalAlignment','left');
    structPopup = uicontrol(fig,'Style','popupmenu','String', ...
        {'S(N(x),y)','S(N(x),T(x,y))','S(T(N(x),N(y)),y)', ...
         'T(S(N(x),y),S(N(y),x))','N(T(x,N(y)))'}, ...
        'Units','normalized','Position',[0.15 0.82 0.3 0.05]);

    lblS   = uicontrol(fig,'Style','text','String','Fuzzy Disjunction [S(x,y)]:','Units','normalized', ...
                       'Position',[0.05 0.72 0.1 0.05],'HorizontalAlignment','left');
    itemsS = {'max(x,y)','x+y-x*y','min(x+y,1)'};
    S_popup = uicontrol(fig,'Style','popupmenu','String',itemsS, ...
                        'Units','normalized','Position',[0.15 0.72 0.3 0.05]);

    lblT   = uicontrol(fig,'Style','text','String','Fuzzy Conjunction [T(x,y)]:','Units','normalized', ...
                       'Position',[0.05 0.62 0.1 0.05],'HorizontalAlignment','left');
    itemsT = {'min(x,y)','x*y','max(x+y-1,0)'};
    T_popup = uicontrol(fig,'Style','popupmenu','String',itemsT, ...
                        'Units','normalized','Position',[0.15 0.62 0.3 0.05]);

    lblN   = uicontrol(fig,'Style','text','String','Fuzzy Negation [N(x)]:','Units','normalized', ...
                       'Position',[0.05 0.50 0.1 0.05],'HorizontalAlignment','left');
    itemsN = {'1-x','(1-x)/(1+lambda*x)','(1-x^w)^(1/w)'};
    N_popup = uicontrol(fig,'Style','popupmenu','String',itemsN, ...
                        'Units','normalized','Position',[0.15 0.50 0.3 0.05], ...
                        'Callback',@negChanged);

    lambdaY     = 0.40; wY = 0.32;
    lambdaLabel = uicontrol(fig,'Style','text','String','λ Parameter:','Units','normalized', ...
                            'Position',[0.05 lambdaY 0.1 0.05],'Visible','off');
    lambdaEdit  = uicontrol(fig,'Style','edit','String','1','Units','normalized', ...
                            'Position',[0.15 lambdaY 0.2 0.05],'Visible','off');
    wLabel       = uicontrol(fig,'Style','text','String','w Parameter:','Units','normalized', ...
                             'Position',[0.05 wY 0.1 0.05],'Visible','off');
    wEdit        = uicontrol(fig,'Style','edit','String','1','Units','normalized', ...
                             'Position',[0.15 wY 0.2 0.05],'Visible','off');

    % Compute button & preview table
    runBtn       = uicontrol(fig,'Style','pushbutton','String','Compute','FontSize',12, ...
                             'Units','normalized','Position',[0.05 0.14 0.4 0.08], ...
                             'Callback',@onRun);
    previewTable = uitable(fig,'Units','normalized','Position',[0.05 0.25 0.4 0.54], ...
                           'Visible','off');

    % Group single‑instance controls
    paramControls = [lblStruct, structPopup, lblS, S_popup, lblT, T_popup, lblN, N_popup];

    % Original startup presets for index dialogs
    presetStruct = structPopup.String{1};
    presetS      = itemsS{1};
    presetT      = itemsT{1};
    presetN      = itemsN{1};
    presetLam    = 1;
    presetW      = 1;

    % Initial UI state
    modeChanged();


    %% --- CALLBACKS --- %%
    function negChanged(~,~)
        sel = N_popup.Value;
        set(lambdaLabel,'Visible',sel==2 && modePopup.Value==1);
        set(lambdaEdit ,'Visible',sel==2 && modePopup.Value==1);
        set(wLabel     ,'Visible',sel==3 && modePopup.Value==1);
        set(wEdit      ,'Visible',sel==3 && modePopup.Value==1);
    end

    function modeChanged(~,~)
        isSingle = (modePopup.Value == 1);
        for h = paramControls
            set(h,'Visible',ternary(isSingle,'on','off'));
        end
        set(previewTable,'Visible',ternary(isSingle,'off','on'));
        cla(ax);
        if ~isSingle
            set(previewTable,'Data',{});
            uistack(runBtn,'top');
        end
    end

    function onRun(~,~)
        mode = modePopup.Value;

        if mode == 1
            % --- Single-model plot ---
            structStr = structPopup.String{structPopup.Value};
            S_str     = S_popup.String{S_popup.Value};
            T_str     = T_popup.String{T_popup.Value};
            N_str     = N_popup.String{N_popup.Value};
            lamVal    = str2double(lambdaEdit.String);
            wVal      = str2double(wEdit.String);

            k = 50; coords = linspace(0,1,k);
            [X,Y] = meshgrid(coords,coords);
            f = buildHandle(structStr,S_str,T_str,N_str,lamVal,wVal);
            Z = f(X,Y); Z = max(min(Z,1),0);

            cla(ax); surf(ax,X,Y,Z);
            xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'I_m');
            return;
        end

        % --- BI / IMV modes ---
        % Ask for k,n
        answer = inputdlg({'Index Depth k (>1):','Index Degree n (≥1):'}, ...
                          'Index Parameters',[1 50;1 50],{'10','1'});
        if isempty(answer), return; end
        k = max(2,round(str2double(answer{1})));
        n = max(1,round(str2double(answer{2})));

        coords = (0:k-1)/(k-1);
        [X,Y] = meshgrid(coords,coords);
        Zall = zeros(k,k,n);

        lockedF = '';

        for j = 1:n
            if j == 1
                % first instance: all pop‑ups at startup presets
                inst = configureInstance( ...
                    presetStruct, presetS, presetT, presetN, ...
                    presetLam, presetW, j, n, false);
                lockedF = inst.struct;
            else
                % subsequent: lock only the F.I.M.
                inst = configureInstance( ...
                    lockedF, presetS, presetT, presetN, ...
                    presetLam, presetW, j, n, true);
            end
            f_j = buildHandle(inst.struct,inst.S,inst.T,inst.N,inst.lambda,inst.w);
            Zall(:,:,j) = f_j(X,Y);
        end

        % Behavior Index per Definition \ref{bi}
        BI  = (1/n) * sum(Zall,3);
        % Intra-model Variability per Definition \ref{ivi}
        IMV = sqrt((1/n) * sum((Zall - BI).^2,3));

        if mode == 2
            M = BI;  ttl = 'Behavior Index (BI)';
        else
            M = IMV; ttl = 'Intra-Model Variability (IMV)';
        end

        cla(ax);
        scatter3(ax,X(:),Y(:),M(:),36,M(:),'filled');
        title(ax,ttl); colorbar(ax);
        set(previewTable,'Data',M);
    end


    %% --- HELPERS --- %%
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
            case 'S(N(x),y)',           core = @(u,v) S_h(N_h(u),v);
            case 'S(N(x),T(x,y))',      core = @(u,v) S_h(N_h(u),T_h(u,v));
            case 'S(T(N(x),N(y)),y)',   core = @(u,v) S_h(T_h(N_h(u),N_h(v)),v);
            case 'T(S(N(x),y),S(N(y),x))', core = @(u,v) T_h(S_h(N_h(u),v),S_h(N_h(v),u));
            case 'N(T(x,N(y)))',        core = @(u,v) N_h(T_h(u,N_h(v)));
        end
        f = @(u,v) max(min(core(u,v),1),0);
    end

    function inst = configureInstance(defStruct,defS,defT,defN,defLam,defW,idx,total,lockStruct)
        % Builds a modal dialog for instance #idx of total.
        % defStruct, defS, defT, defN, defLam, defW serve as the INITIAL
        % values for each popup/edit.  lockStruct disables only the F.I.M. popup.

        dlgW = 460; rows = 6; h = 25; sp = 60; bg = 120;
        dlgH = sp*(rows-1) + h + bg;
        d = dialog('Name',sprintf('Model %d of %d',idx,total), ...
                   'Position',[300 300 dlgW dlgH],'WindowStyle','modal');
        set(d,'WindowKeyPressFcn',@(~,e) onKey(e,d));

        topY = dlgH - 60; Ys = topY - (0:rows-1)*sp;
        lx = 30; lw = 140; cx = lx + lw + 20; cw = 240;

        % F.I.M.
        uicontrol(d,'Style','text','String','F.I.M.:','Position',[lx Ys(1) lw h],...
                  'HorizontalAlignment','right');
        structList = structPopup.String;
        iS = find(strcmp(defStruct,structList),1);
        if isempty(iS), iS = 1; end
        dd1 = uicontrol(d,'Style','popupmenu','String',structList, ...
                        'Position',[cx Ys(1) cw h], ...
                        'Value',iS, ...
                        'Enable',ternary(lockStruct,'inactive','on'));

        % S‑norm
        uicontrol(d,'Style','text','String','Fuzzy Disjunction [S(x,y)]:','Position',[lx Ys(2) lw h],...
                  'HorizontalAlignment','right');
        dd2 = uicontrol(d,'Style','popupmenu','String',itemsS, ...
                        'Position',[cx Ys(2) cw h], ...
                        'Value',find(strcmp(defS,itemsS),1));

        % T‑norm
        uicontrol(d,'Style','text','String','Fuzzy Conjunction [T(x,y)]:','Position',[lx Ys(3) lw h],...
                  'HorizontalAlignment','right');
        dd3 = uicontrol(d,'Style','popupmenu','String',itemsT, ...
                        'Position',[cx Ys(3) cw h], ...
                        'Value',find(strcmp(defT,itemsT),1));

        % Negation
        uicontrol(d,'Style','text','String','Fuzzy Negation [N(x)]:','Position',[lx Ys(4) lw h],...
                  'HorizontalAlignment','right');
        dd4 = uicontrol(d,'Style','popupmenu','String',itemsN, ...
                        'Position',[cx Ys(4) cw h], ...
                        'Value',find(strcmp(defN,itemsN),1));

        % λ parameter
        uicontrol(d,'Style','text','String','λ Parameter:','Position',[lx Ys(5) lw h],...
                  'HorizontalAlignment','right');
        edL = uicontrol(d,'Style','edit','String',num2str(defLam),...
                        'Position',[cx Ys(5) cw h]);

        % w parameter
        uicontrol(d,'Style','text','String','w Parameter:','Position',[lx Ys(6) lw h],...
                  'HorizontalAlignment','right');
        edW = uicontrol(d,'Style','edit','String',num2str(defW),...
                        'Position',[cx Ys(6) cw h]);

        % OK button
        uicontrol(d,'Style','pushbutton','String','OK', ...
                  'Position',[(dlgW-100)/2,10,100,30], ...
                  'Callback',@(~,~) uiresume(d));
        uiwait(d);

        % Collect
        inst.struct = structList{dd1.Value};
        inst.S      = itemsS{dd2.Value};
        inst.T      = itemsT{dd3.Value};
        inst.N      = itemsN{dd4.Value};
        inst.lambda = str2double(edL.String);
        inst.w      = str2double(edW.String);

        delete(d);

        function onKey(evt,dlg)
            if strcmp(evt.Key,'return'), uiresume(dlg); end
        end
    end

    function out = ternary(c,a,b)
        if c, out = a; else out = b; end
    end
end
