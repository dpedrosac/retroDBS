
    dirFolder = dir;      % Get *.nii s for the current directory
    data = {dirFolder.name}';  % Get a list of the folders
    index = contains(data,'pdf');
    data(~index) = [];
    Table_single_Pat_Data = table;
    Table_single_Pat_max_use = table;
    
    for l=1:size(data,1)
        str = extractFileText(data{l,1}); %'Pages', [1]
        str = replace(str,newline,'_'); %replace newline with underscore
        if ~contains(str,'0___12___24___Ho_ur_s')
            disp('no relevant text in file present')
        else
            %% Extract Program # and Percentage Used
            text_date = ['___0___12___24___Ho_ur_s___(?<Percentage_Used>\d+)% Used (?<Days_Used>\d+) Days of Use___Program___(?<Program>\d+)'];
            Info = regexp(str, text_date,'names');
            Info = orderfields(Info, [3 1 2]);
            number_programs = size(Info,2); %str2double(Info(end).Program);
            [percent_most_used_program, i_most_used_program] = max(str2double({Info(1:end).Percentage_Used}));
            clear text_date
            
            
            %% Extract IPG Number
            text_IPG = ['IPG(?<IPG>\d+)|'...
                'IPG___......___(?<IPG>\d+)|'...
                '___(?<IPG>\d+)___Model___Serial'];
            IPG = regexp(str, text_IPG, 'names');
            IPG = IPG(1).IPG;
            Table_IPG(1:number_programs,1) = table(IPG);
            Table_IPG.Properties.VariableNames = {'IPG'};
            clear text_IPG
            
            %% Extract Visit Date
            index_vd = strfind(str,"Visit Date");
            start = index_vd(1)+11;
            fin = start+10;
            Visit_Date = extractBetween(str,start,fin);
            Table_Visit_Date(1:number_programs,1) = table(Visit_Date);
            Table_Visit_Date.Properties.VariableNames = {'Visit_Date'};
            clearvars index_vd start fin
            
            %% Extract DBS Settings
            % Amplitude, Frequency, Impulse Width
            expression = ['(?<Amplitude>\d\.\d)mA___(?<Frequency>\d+)Hz___(?<IW>\d+)|'...
                '(?<Amplitude>\d+)mA___(?<Frequency>\d+)Hz___(?<IW>\d+)'];
            tokenNames = regexp(str,expression,'names');
            clear expression
            
            % Case
            expression = ['CASE_(?<CASE>.\d+)%'];
            CASE = regexp(str, expression, 'names');
            clear expression
            
            %Electrode settings
                                
            expression = ['(?<Contact_1>\d+)%_E1_|' ...
                          '___E1___'];
            Contact_1 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_2>\d+)%_E2_|' ...
                          '___E2___'];
            Contact_2 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_3>\d+)%_E3_|' ...
                          '___E3___'];
            Contact_3 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_4>\d+)%_E4_|' ...
                          '___E4___'];
            Contact_4 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_5>\d+)%_E5_|' ...
                          '___E5___'];
            Contact_5 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_6>\d+)%_E6_|' ...
                          '___E6___'];
            Contact_6 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_7>\d+)%_E7_|' ...
                          '___E7___'];
            Contact_7 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_8>\d+)%_E8_|' ...
                          '___E8___'];
            Contact_8 = regexp(str,expression,'names'); 
            clear expression
            
            expression = ['(?<Contact_9>\d+)%_E9_|' ...
                          '___E9___'];
            Contact_9 = regexp(str,expression,'names'); 
            clear expression   
            
            expression = ['(?<Contact_10>\d+)%_E10_|' ...
                          '___E10___'];
            Contact_10 = regexp(str,expression,'names'); 
            clear expression 
            
            expression = ['(?<Contact_11>\d+)%_E11_|' ...
                          '___E11___'];
            Contact_11 = regexp(str,expression,'names'); 
            clear expression 
            
            expression = ['(?<Contact_12>\d+)%_E12_|' ...
                          '___E12___'];
            Contact_12 = regexp(str,expression,'names'); 
            clear expression 
            
            expression = ['(?<Contact_13>\d+)%_E13_|' ...
                          '___E13___'];
            Contact_13 = regexp(str,expression,'names'); 
            clear expression 
            
            expression = ['(?<Contact_14>\d+)%_E14_|' ...
                          '___E14___'];
            Contact_14 = regexp(str,expression,'names'); 
            clear expression 
            
            expression = ['(?<Contact_15>\d+)%_E15_|' ...
                          '___E15___'];
            Contact_15 = regexp(str,expression,'names'); 
            clear expression 
            
            expression = ['(?<Contact_16>\d+)%_E16_|' ...
                          '___E16___'];
            Contact_16 = regexp(str,expression,'names'); 
            clear expression 
            
            
                
                Contacts = [struct2cell(Contact_1')', struct2cell(Contact_2')', struct2cell(Contact_3')', struct2cell(Contact_4')', ...
                    struct2cell(Contact_5')', struct2cell(Contact_6')', struct2cell(Contact_7')', struct2cell(Contact_8')', ...
                    struct2cell(Contact_9')', struct2cell(Contact_10')', struct2cell(Contact_11')', struct2cell(Contact_12')', ...
                    struct2cell(Contact_13')', struct2cell(Contact_14')', struct2cell(Contact_15')', struct2cell(Contact_16')']; %concatenate all Contacts
                
                TF = arrayfun(@(k) isempty(Contacts{k}), 1:(size(Contacts,1)*size(Contacts,2))); %find index of empty cells in cellarray
                Contacts(TF) = num2cell(0); %replace empty cells with 0
                
                Contacts = cell2table(Contacts);
                
                Contacts.Properties.VariableNames = {'Contact_1', 'Contact_2', 'Contact_3', ...
                    'Contact_4', 'Contact_5', 'Contact_6', 'Contact_7', 'Contact_8',  ...
                    'Contact_9', 'Contact_10', 'Contact_11', 'Contact_12', 'Contact_13', ...
                    'Contact_14', 'Contact_15', 'Contact_16'};
                
                clearvars Contact_1 Contact_2 Contact3 Contact_4 Contact_6 ...
                        Contact_7 Contact_8 Contact_9 Contact_10 Contact_11 Contact_12 Contact_13 Contact_14 Contact_15 Contact_16
            
            
            dbs_settings_left = struct2table(tokenNames(1:2:end));
            dbs_settings_right = struct2table(tokenNames(2:2:end));
            dbs_settings_left.Properties.VariableNames = {'Amplitude_Left_STN', 'Frequency_Left_STN', 'IW_Left_STN'};
            dbs_settings_right.Properties.VariableNames = {'Amplitude_Right_STN', 'Frequency_Right_STN', 'IW_Right_STN'};
            dbs_settings = [dbs_settings_left, dbs_settings_right];
            
            CASE_Left = struct2table(CASE(1:2:end));
            CASE_Right = struct2table(CASE(2:2:end));
            CASE_Left.Properties.VariableNames = {'Case_Left'};
            CASE_Right.Properties.VariableNames = {'Case_Right'};
            Table_CASE = [CASE_Left, CASE_Right];
            
            % Create Table comprising all Pt data
            Table = [Table_IPG, Table_Visit_Date, struct2table(Info), Contacts, ...
              Table_CASE, dbs_settings]; 
            
            Table_single_Pat_Data = vertcat(Table_single_Pat_Data, Table);
            
            
            % Create Table comprising Pt data of Program mainly used
            Table_single_Pat_max_use(l,:) = Table(i_most_used_program,:);
            
            
            clearvars Table Table_IPG Table_Visit_Date Contacts_Left Contacts_Right Contacts dbs_settings_left dbs_settings_right dbs_settings CASE_Left CASE_Right ...
                Table_CASE number_programs
        end
    end
    writetable(Table_single_Pat_Data, strcat(IPG, '_all_Data.xlsx'));
    writetable(Table_single_Pat_max_use, strcat(IPG, '_Data_max_usage.xlsx'));
    
    %% Create Table comprising most used Programs of all Pts
    Table_all_Pat_max_use = vertcat(Table_all_Pat_max_use, Table_single_Pat_max_use);
    clearvars Table_single_Pat_max_use Table_single_Pat_Data

writetable(Table_all_Pat_max_use, 'All_Pts_Data_max_usage.xlsx');

toc
