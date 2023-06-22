
clear all
close all

table_pts = readtable('All_Pts_Data_max_usage.xlsx');

IPG = [738669
700648
700459
700412
700405
735020
700520
735022
735023
735018
735044
735244
735603
736291
736707
736632
736515
736723
736505
736675
736433
736497
736828
736663
736723
737398
737320
738709
737362
738753
738720
738704
740428
739205
739190
739504
741147
741074
740154
741824
741328
501749];

table_new = table;

for i = 1:size(IPG,1)
    
idx = find (table_pts.IPG == IPG(i,1), 1, 'last');
table_new(i,:) = table_pts(idx,:);
  
end
writetable(table_new, 'inf_last_visit.xlsx');
