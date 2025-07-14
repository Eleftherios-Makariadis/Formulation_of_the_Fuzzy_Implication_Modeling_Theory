function FoFIMT_v10

    % Main window
    fig = figure('Name','FoFIMT','NumberTitle','off', ...
                 'Position',[200 200 1000 600]);

    % 3D axes (always visible)
    ax = axes(fig,'Units','normalized','Position',[0.55 0.10 0.40 0.85]);
    view(ax,[45 30]); grid(ax,'on');

    % Mode selector (always visible)
    uicontrol(fig,'Style','text','String','Program Mode:','Units','normalized', ...
              'Position',[0.05 0.90 0.1 0.05],'HorizontalAlignment','left');
    modePopup = uicontrol(fig,'Style','popupmenu', ...
        'String',{'Single F.I.M. Instance','Behavior Index (BI)', ...
                 'Intra-Model Variability Index (IMV)'}, ...
        'Units','normalized','Position',[0.15 0.90 0.3 0.05], ...
        'Callback',@modeChanged);

    % F.I.M.
    lblStruct   = uicontrol(fig,'Style','text','String','F.I.M.:','Units','normalized', ...
                            'Position',[0.05 0.82 0.1 0.05],'HorizontalAlignment','left');
    structPopup = uicontrol(fig,'Style','popupmenu', ...
        'String',{'S(N(x),y)','S(N(x),T(x,y))','S(T(N(x),N(y)),y)', ...
                 'T(S(N(x),y),S(N(y),x))','N(T(x,N(y)))'}, ...
        'Units','normalized','Position',[0.15 0.82 0.3 0.05]);

    % S-norm
    lblS    = uicontrol(fig,'Style','text','String','Fuzzy Disjunction [S(x,y)]:','Units','normalized', ...
                        'Position',[0.05 0.72 0.1 0.05],'HorizontalAlignment','left');
    itemsS  = {'max(x,y)','x+y-x*y','min(x+y,1)'};
    S_popup = uicontrol(fig,'Style','popupmenu','String',itemsS, ...
                        'Units','normalized','Position',[0.15 0.72 0.3 0.05], ...
                        'Callback',@normChanged);

    % T-norm
    lblT    = uicontrol(fig,'Style','text','String','Fuzzy Conjunction [T(x,y)]:','Units','normalized', ...
                        'Position',[0.05 0.62 0.1 0.05],'HorizontalAlignment','left');
    itemsT  = {'min(x,y)','x*y','max(x+y-1,0)'};
    T_popup = uicontrol(fig,'Style','popupmenu','String',itemsT, ...
                        'Units','normalized','Position',[0.15 0.62 0.3 0.05], ...
                        'Callback',@normChanged);

    % Negation
    lblN    = uicontrol(fig,'Style','text','String','Fuzzy Negation [N(x)]:','Units','normalized', ...
                        'Position',[0.05 0.50 0.1 0.05],'HorizontalAlignment','left');
    itemsN  = {'1-x','(1-x)/(1+lambda*x)','(1-x^w)^(1/w)'};
    N_popup = uicontrol(fig,'Style','popupmenu','String',itemsN, ...
                        'Units','normalized','Position',[0.15 0.50 0.3 0.05], ...
                        'Callback',@negChanged);

    % Lambda & w (hidden until needed)
    lambdaY = 0.40; wY = 0.32;
    lambdaLabel = uicontrol(fig,'Style','text','String','λ Parameter:','Units','normalized', ...
                            'Position',[0.05 lambdaY 0.1 0.05],'Visible','off');
    lambdaEdit  = uicontrol(fig,'Style','edit','String','1','Units','normalized', ...
                            'Position',[0.15 lambdaY 0.2 0.05],'Visible','off');
    wLabel = uicontrol(fig,'Style','text','String','w Parameter:','Units','normalized', ...
                       'Position',[0.05 wY 0.1 0.05],'Visible','off');
    wEdit   = uicontrol(fig,'Style','edit','String','1','Units','normalized', ...
                        'Position',[0.15 wY 0.2 0.05],'Visible','off');

    % Compute button (always visible)
    runBtn = uicontrol(fig,'Style','pushbutton','String','Compute','FontSize',12, ...
                       'Units','normalized','Position',[0.05 0.14 0.4 0.08], ...
                       'Callback',@onRun);

    % Preview table (hidden until BI/IMV mode)
    previewTable = uitable(fig,'Units','normalized', ...
                           'Position',[0.05 0.25 0.4 0.54], ...
                           'Visible','off');

    % Which controls to show/hide as a group
    paramControls = [lblStruct, structPopup, lblS, S_popup, lblT, T_popup, lblN, N_popup];

    % Kick things off
    modeChanged();

    %% --- CALLBACKS ---
    %Placeholder for future features
    function normChanged(~,~)
        % no custom inputs
    end

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
            set(h,'Visible', ternary(isSingle,'on','off'));
        end
        set(previewTable,'Visible', ternary(isSingle,'off','on'));
        cla(ax);

        if ~isSingle
            set(previewTable,'Data',{});    % blank placeholder
            uistack(runBtn,'top');
        else
            normChanged();
            negChanged();
        end
    end

function onRun(~,~)
    mode      = modePopup.Value;
    structStr = structPopup.String{structPopup.Value};

    S_str  = S_popup.String{S_popup.Value};
    T_str  = T_popup.String{T_popup.Value};
    N_str  = N_popup.String{N_popup.Value};
    lamVal = str2double(lambdaEdit.String);
    wVal   = str2double(wEdit.String);

    if mode == 1
        % --- Single-model surface plot ---
        k = 50;
        coords = linspace(0,1,k);
        [X,Y] = meshgrid(coords,coords);
        f = buildHandle(structStr,S_str,T_str,N_str,lamVal,wVal);
        Z = f(X,Y);
        Z = max(min(Z,1),0);
        cla(ax); surf(ax,X,Y,Z);
        xlabel(ax,'X'); ylabel(ax,'Y'); zlabel(ax,'I_m');
    else
        % --- BI/IMV per the paper's definitions ---
        prompt   = {'Index Depth k (>1):','Index Degree n (≥1):'};
        dims     = [1 50; 1 50];
        dlgtitle = 'Index Parameters';
        definput = {'10','1'};
        answer   = inputdlg(prompt,dlgtitle,dims,definput);
        if isempty(answer), return; end

        k = max(2,round(str2double(answer{1})));
        n = max(1,round(str2double(answer{2})));
        coords = (0:k-1)/(k-1);
        [X,Y] = meshgrid(coords,coords);

        Zall = zeros(k,k,n);
        lockStruct = false;
        for j = 1:n
            inst = configureInstance( ...
                structStr, S_str, T_str, N_str, lamVal, wVal, j, n, lockStruct);
            lockStruct = true;
            f_j = buildHandle(inst.struct,inst.S,inst.T,inst.N,inst.lambda,inst.w);
            Zall(:,:,j) = f_j(X,Y);
        end

        % Behavior Index:
        BI  = (1/n) * sum(Zall,3);
        % IMV: 
        IMV = sqrt((1/n) * sum((Zall - BI).^2,3));

        if mode == 2
            M   = BI;
            ttl = 'Behavior Index (BI)';
        else
            M   = IMV;
            ttl = 'Intra-model Variability (IMV)';
        end

        cla(ax);
        scatter3(ax, X(:), Y(:), M(:), 36, M(:), 'filled');
        title(ax, ttl);
        colorbar(ax);

        set(previewTable,'Data',M);
    end
end


    %% --- HELPERS ---

    function f = buildHandle(ss,Ss,Ts,Ns,lam,w)
        % Convert user strings to safe, elementwise MATLAB expressions
        safeOps = { '\^', '.^';  '(\*)', '.*';  '(/)', './' };
        exprS = Ss; exprT = Ts; exprN = Ns;
        % replace x->u, y->v
        exprS = regexprep(exprS,'\<x\>','u'); exprS = regexprep(exprS,'\<y\>','v');
        exprT = regexprep(exprT,'\<x\>','u'); exprT = regexprep(exprT,'\<y\>','v');
        exprN = regexprep(exprN,'\<x\>','u');
        % enforce elementwise ops
        for k=1:size(safeOps,1)
            exprS = regexprep(exprS, safeOps{k,1}, safeOps{k,2});
            exprT = regexprep(exprT, safeOps{k,1}, safeOps{k,2});
            exprN = regexprep(exprN, safeOps{k,1}, safeOps{k,2});
        end
        % substitute numeric parameters into negation
        exprN = strrep(exprN,'lambda',num2str(lam));
        exprN = strrep(exprN,'w',     num2str(w));
        % build handles safely
        try
            S_h = str2func(['@(u,v)' exprS]);
            T_h = str2func(['@(u,v)' exprT]);
            N_h = str2func(['@(u)'   exprN]);
        catch ME
            errordlg(['Invalid expression: ' ME.message],'Parse Error');
            f = @(u,v) nan(size(u));
            return;
        end
        % Compose and clamp final output
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
        end
        f = @(u,v) max(min(core(u,v),1),0);
    end

function inst = configureInstance(defStruct,defS,defT,defN,defLam,defW,idx,total,lockStruct)
    % Layout parameters
    dlgWidth    = 460;
    nRows       = 6;
    rowH        = 25;
    spacing     = 60;             
    bottomGap   = 120;            
    dlgHeight   = spacing*(nRows-1) + rowH + bottomGap;

    % Column positions
    labelX   = 30;                
    labelW   = 140;               
    ctrlX    = labelX + labelW + 20;  
    ctrlW    = 240;               

    % Create dialog
    d = dialog('Name', sprintf('Model %d of %d',idx,total), ...
               'Position',[300 300 dlgWidth dlgHeight], ...
               'WindowStyle','modal');

    % Make Enter key trigger OK
    set(d, 'WindowKeyPressFcn', @onKeyPress);

    % Compute Y positions, top to bottom
    topY = dlgHeight - 60;
    Ys   = topY - (0:nRows-1)*spacing;

    % Row 1: F.I.M.
    uicontrol(d,'Style','text', ...
              'String','F.I.M.:', ...
              'Position',[labelX Ys(1) labelW rowH], ...
              'HorizontalAlignment','right');
    structList = structPopup.String;
    iS = find(strcmp(defStruct,structList),1,'first');
    if isempty(iS), iS = 1; end
    ddStr = uicontrol(d,'Style','popupmenu', ...
                     'String',structList, ...
                     'Position',[ctrlX Ys(1) ctrlW rowH], ...
                     'Value',iS, ...
                     'Enable',ternary(lockStruct,'inactive','on'));

    % Row 2: S‐norm
    uicontrol(d,'Style','text', ...
              'String','Fuzzy Disjunction [S(x,y)]:', ...
              'Position',[labelX Ys(2) labelW rowH], ...
              'HorizontalAlignment','right');
    iSS = find(strcmp(defS,itemsS),1,'first');
    if isempty(iSS), iSS = 1; end
    ddS2 = uicontrol(d,'Style','popupmenu', ...
                     'String',itemsS, ...
                     'Position',[ctrlX Ys(2) ctrlW rowH], ...
                     'Value',iSS);

    % Row 3: T‐norm
    uicontrol(d,'Style','text', ...
              'String','Fuzzy Conjunction [T(x,y)]:', ...
              'Position',[labelX Ys(3) labelW rowH], ...
              'HorizontalAlignment','right');
    iTT = find(strcmp(defT,itemsT),1,'first');
    if isempty(iTT), iTT = 1; end
    ddT2 = uicontrol(d,'Style','popupmenu', ...
                     'String',itemsT, ...
                     'Position',[ctrlX Ys(3) ctrlW rowH], ...
                     'Value',iTT);

    % Row 4: Negation
    uicontrol(d,'Style','text', ...
              'String','Fuzzy Negation [N(x)]:', ...
              'Position',[labelX Ys(4) labelW rowH], ...
              'HorizontalAlignment','right');
    iNN = find(strcmp(defN,itemsN),1,'first');
    if isempty(iNN), iNN = 1; end
    ddN2 = uicontrol(d,'Style','popupmenu', ...
                     'String',itemsN, ...
                     'Position',[ctrlX Ys(4) ctrlW rowH], ...
                     'Value',iNN);

    % Row 5: λ Parameter
    uicontrol(d,'Style','text', ...
              'String','λ Parameter:', ...
              'Position',[labelX Ys(5) labelW rowH], ...
              'HorizontalAlignment','right');
    edLam2 = uicontrol(d,'Style','edit', ...
                      'String',num2str(defLam), ...
                      'Position',[ctrlX Ys(5) ctrlW rowH]);

    % Row 6: w Parameter
    uicontrol(d,'Style','text', ...
              'String','w Parameter:', ...
              'Position',[labelX Ys(6) labelW rowH], ...
              'HorizontalAlignment','right');
    edW2 = uicontrol(d,'Style','edit', ...
                     'String',num2str(defW), ...
                     'Position',[ctrlX Ys(6) ctrlW rowH]);

    % OK button 
    btnW = 100; btnH = 30;
    okBtn = uicontrol(d,'Style','pushbutton', ...
                      'String','OK', ...
                      'Position',[ (dlgWidth - btnW)/2, 10, btnW, btnH ], ...
                      'Callback',@(~,~) uiresume(d));

    uiwait(d);

    % Collect results
    inst.struct = structList{ddStr.Value};
    inst.S      = itemsS{ddS2.Value};
    inst.T      = itemsT{ddT2.Value};
    inst.N      = itemsN{ddN2.Value};
    inst.lambda = str2double(edLam2.String);
    inst.w      = str2double(edW2.String);
    delete(d);

    % Nested function to catch Enter key
    function onKeyPress(~,evt)
        if strcmp(evt.Key,'return')
            uiresume(d);
        end
    end
end



    function out = ternary(c,a,b)
        if c, out = a; else out = b; end
    end
end
