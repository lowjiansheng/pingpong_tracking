function visualize(mat,linespec)
%VISUALIZE3DMAT Summary of this function goes here
%   Detailed explanation goes here

    cell_mat = num2cell(mat, 1);
    plot3(cell_mat{:}, linespec);    
end

