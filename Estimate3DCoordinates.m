function output = Estimate3DCoordinates(cam1, cam2, cam3, cam1_img_pts, cam2_img_pts, cam3_img_pts)
%ESTIMATE3DCOORDINATES Summary of this function goes here
%   Detailed explanation goes here
if ~isa(cam1, 'Camera') || ~isa(cam2, 'Camera')
    error('Wrong input types')
end
if ~(size(cam1_img_pts) == size(cam2_img_pts))
    error('Mismatch size')
end
num_correspondence = size(cam1_img_pts,1);

cam1_img_pts_dir_vectors = (cam1.axes*[cam1_img_pts zeros(num_correspondence, 1)+cam1.getFLen() ]');
cam2_img_pts_dir_vectors = (cam2.axes*[cam2_img_pts zeros(num_correspondence, 1)+cam2.getFLen() ]');
cam3_img_pts_dir_vectors = (cam3.axes*[cam3_img_pts zeros(num_correspondence, 1)+cam3.getFLen() ]');

output = zeros(num_correspondence,3,4);
for i=1:num_correspondence
    cam1_img_pt_dir_vec = cam1_img_pts_dir_vectors(:,i);
    cam2_img_pt_dir_vec = cam2_img_pts_dir_vectors(:,i);
    cam3_img_pt_dir_vec = cam3_img_pts_dir_vectors(:,i);
    
    if sum(isnan(cam1_img_pt_dir_vec + cam2_img_pt_dir_vec)) > 0
        output(i,:,:) = nan(1,3,4);
        continue
    end
    A = cat(1,...
            cat(2, cam1_img_pt_dir_vec, -cam2_img_pt_dir_vec, zeros(3,1)),...
            cat(2, cam1_img_pt_dir_vec, zeros(3,1), -cam3_img_pt_dir_vec),...
            cat(2, zeros(3,1), cam2_img_pt_dir_vec, -cam3_img_pt_dir_vec));
    b = cat(1,...
            cam2.position-cam1.position,...
            cam3.position-cam1.position,...
            cam3.position-cam2.position);
    x = inv(A'*A)*A'*b;
    
    sol1 = cam1_img_pt_dir_vec * x(1) + cam1.position;
    sol2 = cam2_img_pt_dir_vec * x(2) + cam2.position;
    sol3 = cam3_img_pt_dir_vec * x(3) + cam3.position;
    output(i,:,1) = sol1';
    output(i,:,2) = sol2';
    output(i,:,3) = sol3';
    output(i,:,4) = (sol1+sol2+sol3)/3;
end

