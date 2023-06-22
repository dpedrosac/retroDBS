clear all 
close all

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
            %Due to the readin of the PDF File no distinction can be made whether
            %Contact 4 or 3 is active, in case of a single active contact. One has to
            % manually check whether Contact 4 or 3 was active (see IPG500277
            % for an example). This holds true for most other single active
            % contacts except 1, 8, 9, and 16.
            
            expression = ['___4___2___3_|'... % no contact active   +
                '(?<Contact_4>\d+)%___4___2___3_?|'... %contact 4 active, example from IPG500277 Program 1
                '(?<Contact_4>\d+)%___4___2___3_+|'...
                '(?<Contact_2>\d+)%___4___2___3___?|'... %contact 2 active, example from IPG601009 Program 2
                '(?<Contact_2>\d+)%___4___2___3___+|'...
                '(?<Contact_4>\d+)%___(?<Contact_2>\d+)%___4___2___3___?___?|'... % contact 4 and 2 active, example from IPG739205 Program 2
                '(?<Contact_4>\d+)%___(?<Contact_2>\d+)%___4___2___3___+___+|'...
                '(?<Contact_2>\d+)%___(?<Contact_3>\d+)%___4___2___3_?___?|'... %contact 2 and 3 active, example from IPG 601476 Program 1
                '(?<Contact_2>\d+)%___(?<Contact_3>\d+)%___4___2___3_+___+|'...
                '(?<Contact_4>\d+)% (?<Contact_3>\d+)%___4___2___3___??|'... %contact 4 and 3 active, example from IPG 600584 Program 4
                '(?<Contact_4>\d+)% (?<Contact_3>\d+)%___4___2___3___++|'...
                '(?<Contact_4>\d+)%___(?<Contact_2>\d+)%___(?<Contact_3>\d+)%___4___2___3_']; % all contacts active
            Contact_4 = regexp(str,expression,'names');
            Contact_4 = orderfields(Contact_4, [2 3 1]);
            clear expression
            
            expression = ['___1__|'...
                '(?<Contact_1>\d+)%___1___(?<Polarity_1>.)'];
            Contact_1 = regexp(str,expression,'names');
            clear expression
            
            expression = ['___7___5___6_|'...
                '(?<Contact_7>\d+)%___7___5___6_?|'...
                '(?<Contact_5>\d+)%___7___5___6___?|'...
                '(?<Contact_7>\d+)%___(?<Contact_5>\d+)%___7___5___6___?___?|'...
                '(?<Contact_5>\d+)%___(?<Contact_6>\d+)%___7___5___6_?___?|'...
                '(?<Contact_7>\d+)% (?<Contact_6>\d+)%___7___5___6___??|'...
                '(?<Contact_7>\d+)%___7___5___6_+|'...
                '(?<Contact_5>\d+)%___7___5___6___+|'...
                '(?<Contact_7>\d+)%___(?<Contact_5>\d+)%___7___5___6___+___+|'...
                '(?<Contact_5>\d+)%___(?<Contact_6>\d+)%___7___5___6_+___+|'...
                '(?<Contact_7>\d+)% (?<Contact_6>\d+)%___7___5___6___++|'...
                '(?<Contact_7>\d+)%___(?<Contact_5>\d+)%___(?<Contact_6>\d+)%___7___5___6_'];
            Contact_7 = regexp(str,expression,'names');
            Contact_7 = orderfields(Contact_7, [2 3 1]);
            clear expression
            
            expression = ['_8___(\d+\.\d+)mA|'...
                '_8___(\d+)mA|'...
                '_8___C|'...
                '_8___(?<Contact_8>\d+)%_(?<Polarity_8>.)'];
            Contact_8 = regexp(str,expression,'names');
            clear expression
            
            
            %% search for Right STN electrodes' names
            
            if contains(str,'12___10___11')
                
                
                expression = ['___12___10___11_|'... % no contact active
                    '(?<Contact_12>\d+)%___12___10___11_?|'... %contact 12 active
                    '(?<Contact_10>\d+)%___12___10___11___?|'... %contact 10 active
                    '(?<Contact_12>\d+)%___(?<Contact_10>\d+)%___12___10___11___?___?|'... % contact 12 and 10 active
                    '(?<Contact_10>\d+)%___(?<Contact_11>\d+)%___12___10___11_?___?|'... %contact 10 and 11 active
                    '(?<Contact_12>\d+)% (?<Contact_11>\d+)%___12___10___11___??|'... %contact 10 and 11 active
                    '(?<Contact_12>\d+)%___12___10___11_+|'... %contact 12 active
                    '(?<Contact_10>\d+)%___12___10___11___+|'... %contact 10 active
                    '(?<Contact_12>\d+)%___(?<Contact_10>\d+)%___12___10___11___+___+|'... % contact 12 and 10 active
                    '(?<Contact_10>\d+)%___(?<Contact_11>\d+)%___12___10___11_+___+|'... %contact 10 and 11 active
                    '(?<Contact_12>\d+)% (?<Contact_11>\d+)%___12___10___11___++|'... %contact 10 and 11 active
                    '(?<Contact_12>\d+)%___(?<Contact_10>\d+)%___(?<Contact_11>\d+)%___12___10___11_']; % all contacts active
                Contact_12 = regexp(str,expression,'names');
                Contact_12 = orderfields(Contact_12, [2 3 1]);
                clear expression
                
                expression = ['___9__|'...
                    '(?<Contact_9>\d+)%___9___(?<Polarity_9>.)'];
                Contact_9 = regexp(str,expression,'names');
                
                clear expression
                
                
                expression = ['___15___13___14_|'...
                    '(?<Contact_15>\d+)%___15___13___14_?|'...
                    '(?<Contact_13>\d+)%___15___13___14___?|'...
                    '(?<Contact_15>\d+)%___(?<Contact_13>\d+)%___15___13___14___?___?|'...
                    '(?<Contact_13>\d+)%___(?<Contact_14>\d+)%___15___13___14_?___?|'...
                    '(?<Contact_15>\d+)% (?<Contact_14>\d+)%___15___13___14___??|'...
                    '(?<Contact_15>\d+)%___15___13___14_+|'...
                    '(?<Contact_13>\d+)%___15___13___14___+|'...
                    '(?<Contact_15>\d+)%___(?<Contact_13>\d+)%___15___13___14___+___+|'...
                    '(?<Contact_13>\d+)%___(?<Contact_14>\d+)%___15___13___14_+___+|'...
                    '(?<Contact_15>\d+)% (?<Contact_14>\d+)%___15___13___14___++|'...
                    '(?<Contact_15>\d+)%___(?<Contact_13>\d+)%___(?<Contact_14>\d+)%___15___13___14_'];
                Contact_15 = regexp(str,expression,'names');
                Contact_15 = orderfields(Contact_15, [2 3 1]);
                clear expression
                
                expression = ['_16___(\d+\.\d+)mA|'...
                    '_16___(\d+)mA|'...
                    '_16___C|'...
                    '_16___D|'...
                    '_16___(?<Contact_16>\d+)%_(?<Polarity_16>.)'];
                Contact_16 = regexp(str,expression,'names');
                clear expression
                
                Contacts = [struct2cell(Contact_9')', struct2cell(Contact_12')', ...
                    struct2cell(Contact_15')', struct2cell(Contact_16')']; %concatenate all Contacts
                
                TF = arrayfun(@(k) isempty(Contacts{k}), 1:(size(Contacts,1)*size(Contacts,2))); %find index of empty cells in cellarray
                Contacts(TF) = num2cell(0); %replace empty cells with 0
                
                Contacts = cell2table(Contacts);
                
                Contacts.Properties.VariableNames = {'Contact_9', 'Polarity_9', 'Contact_10', 'Contact_11', 'Contact_12', 'Contact_13', ...
                    'Contact_14', 'Contact_15', 'Contact_16', 'Polarity_16'};
                
                clearvars Contact_9 Contact_12 Contact_15 Contact_16
                
            else
                
                
                Contacts= [struct2cell(Contact_1')', struct2cell(Contact_4')', ...
                    struct2cell(Contact_7')', struct2cell(Contact_8')'];
                
                TF = arrayfun(@(k) isempty(Contacts{k}), 1:(size(Contacts,1)*size(Contacts,2))); %find index of empty cells in cellarray
                Contacts(TF) = num2cell(0); %replace empty cells with 0
                Contacts = cell2table(Contacts);
                
                Contacts.Properties.VariableNames = {'Contact_1', 'Polarity_1', 'Contact_2', 'Contact_3', ...
                    'Contact_4', 'Contact_5', 'Contact_6', 'Contact_7', 'Contact_8', 'Polarity_8'};
                
                clearvars Contact_1 Contact_4 Contact_7 Contact_8
            end
            
            dbs_settings = struct2table(tokenNames);
            
            dbs_settings.Properties.VariableNames = {'Amplitude_Left_STN', 'Frequency_Left_STN', 'IW_Left_STN'};
           
            
            Table_CASE = struct2table(CASE);
            
            Table_CASE.Properties.VariableNames = {'Case_Left'};
            
            
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
    
