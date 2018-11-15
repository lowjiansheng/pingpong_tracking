function tables = cleanData(tables)
%CLEANDATA Summary of this function goes here
%   Remove bad data retains frame number for comaparison

% Ignore the NaNs
for i=1:size(tables,2)
    table = tables{i};
    rows_w_nan = sum(isnan(table{:,:}), 2) > 0;
    tables = del_rows(tables, rows_w_nan);
end

% Ignore the negatives. 
% TODO: Why are there negatives? Someone should investigate!
for i=1:size(tables,2)
    table = tables{i};    
    rows_w_neg = sum(table{:,:} < 0, 2) > 0;    
    tables = del_rows(tables, rows_w_neg);
end

end

function output = del_rows(tables, rows)
if sum(rows) > 0
    for i=1:size(tables,2)
    table = tables{i};
    table(rows, :) = [];
    tables{i} = table;
    end
end

output = tables;
end

