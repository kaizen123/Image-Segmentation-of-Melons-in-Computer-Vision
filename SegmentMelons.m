function SegmentMelons( fn )
% This function identifies the melons from the background and draws a blue
% line between the skin and the melons. It also counts the number of melons
% that are present in the image.

close all;
% set interactive = 2 if you just want to use the exisitng model
% set interactive = 1 if you want to create your own model
INTERACTIVE = 2;

if nargin < 1
    % There is no file name provided.
    fn = 'img_cantaloupe_slices_1292.jpg';
    %fn = 'img_cantaloupe_slices_1251.jpg';
    file_name = fn;
else
    % file name is provided.
    file_name = fn;
    % fn = 'img_cantaloupe_slices_1251.jpg'; 
end

if  INTERACTIVE == 1
    % ask the user for different classes such as the pulp of the melon, the
    % skin of the melon and the backfround.
    
    % read the image and convert it into double
    im_rgb = im2double(imread( fn ));
    % display the image
    figure('Position',[10 10 1024 768]);
    imshow( im_rgb );
    % ask the user to select the pulp part of the melon
    fprintf('Select pulp of the melon:');
    fprintf('Click on points to capture positions:  Hit return to end...\n');
    % store the clicks
    [x_fg, y_fg] = ginput();
    
    % ask the user to select the skin part of the melon
    fprintf('SELECT SKIN OBJECT ... ');
    fprintf('Click on points to capture positions:  Hit return to end...\n');
    % store the clicks
    [x_sg, y_sg] = ginput();

    % ask the user to select the background of the image which is the cutting board
    fprintf('SELECT BACKGROUND OBJECT ... ');
    fprintf('Click on points to capture positions:  Hit return to end...\n');
    % store the clicks
    [x_bg, y_bg] = ginput();
    input_image = im_rgb;
    clear file_name;
    % save your selected points (model)
    %save my_temporary_data2;
else
    % use the exisiting model created
    load my_temporary_data2;
    input_image = im2double(imread(file_name));
end

figure; imshow(input_image); pause(5);
%file_name

% % get the cielab color space 
% im_lab      = rgb2lab( input_image );
% % get the a and b color channel of cielab
% im_a        = im_lab(:,:,2);
% im_b        = im_lab(:,:,3);
% 
% % since our x and y values of pulp are accurate, round it off to the
% % nearest value, then call sub2ind which converts subscripts to linear
% % indices
% fg_indices  = sub2ind( size(im_lab), round(y_fg), round(x_fg) );
% fg_a        = im_a( fg_indices );
% fg_b        = im_b( fg_indices );
% 
% % since our x and y values of skin are accurate, round it off to the
% % nearest value, then call sub2ind which converts subscripts to linear
% % indices
% sg_indices  = sub2ind( size(im_lab), round(y_sg), round(x_sg) );
% sg_a        = im_a( sg_indices );
% sg_b        = im_b( sg_indices );
% 
% % since our x and y values of background are accurate, round it off to the
% % nearest value, then call sub2ind which converts subscripts to linear
% % indices
% bg_indices  = sub2ind( size(im_lab), round(y_bg), round(x_bg) );
% bg_a        = im_a( bg_indices );
% bg_b        = im_b( bg_indices );
% 
% % this forms the vector of two features that are obtained of the pulp.
% fg_ab       = [ fg_a fg_b ];
% 
% % their mean and covariance which is the spread of the color. can be used instead of the mahal function                                          
% % mean_fg     = mean( fg_ab );
% % cov_fg      = cov( fg_ab );
% 
% % this forms the vector of two features that are obtained of the skin.
% sg_ab       = [ sg_a sg_b ]; 
% 
% % their mean and covariance which is the spread of the color. can be used instead of the mahal function                                          
% % mean_fg     = mean( sg_ab );                    
% % cov_fg      = cov( sg_ab );
% 
% % this forms the vector of two features that are obtained of the background.
% bg_ab       = [ bg_a bg_b ];
% 
% % their mean and covariance which is the spread of the color. can be used instead of the mahal function                                          
% % mean_bg     = mean( bg_ab );           
% % cov_bg      = cov( bg_ab ); 
% 
% % combines the two color channels into one vector
% im_ab       = [ im_a(:) im_b(:) ];
% clear file_name, fn, im_ab;
% save my_temporary_data2;

% get the cielab color space 
im_lab      = rgb2lab( input_image );
% get the a and b color channel of cielab
im_a        = im_lab(:,:,2);
im_b        = im_lab(:,:,3);
im_ab       = [ im_a(:) im_b(:) ];

% call the mahal function of MATALB to calculate the Mahalanobis distance
% of the features in the color channel. this return the square of the
% distance, hence to get the distance take the root of that
mahal_fg    = ( mahal( im_ab, fg_ab ) ) .^ (1/2);
mahal_sg    = ( mahal( im_ab, sg_ab ) ) .^ (1/2);
mahal_bg    = ( mahal( im_ab, bg_ab ) ) .^ (1/2);

% Classify as Class 0 (pulp of the melon object) if distance to FG is < distance to BG
% this class is not required to compute here
class_0     = mahal_fg < mahal_bg;
% reshape this class to the get the original dimension of the image
class_im    = reshape( class_0, size(im_a,1), size(im_a,2) );

% Classify as Class 1 (skin of the melon object) if distance to SG is < distance to FG
class_1     = mahal_sg < mahal_fg;
% reshape this class to the get the original dimension of the image
class_im1    = reshape( class_1, size(im_a,1), size(im_a,2) );

% define a structuring element for morphology
se = strel('disk',5);
% perform opening: first erosion then dilation to remove any noise in the
% image
im_skin = imopen(class_im1, se);
% define a new structuring element for different morphology
se = strel('disk',10);
% perform dilation which thicken the skin of the melon
im_skin2 = imdilate(im_skin,se);
% figure; imshow(im_skin2);

% call bwlabel function to identify the number of objects detected in the
% image ( skins + extra objects that might be included )
[region_map,count_of_regions] = bwlabel( im_skin2, 4 );

% display the original image so that the blue line can be plotted on top of
% it
figure; imshow(input_image); hold on;
% variable to count number of melons present
number_of_melons = 0;
% loop through the number of objects found in the image
for blob_idx = 1:count_of_regions
    % get each objects
    b_one_region = (region_map == blob_idx);
    % obtain the area of the region found, if the area is too less then
    % it is probably not the skin of the melon
    region_area = regionprops(b_one_region,'Area');
    if (sum(region_area.Area) > 15000)
        % it is the skin of the melon
        number_of_melons = number_of_melons + 1;
        % perform erosion the reduce the thickness of the skin
        b_1 = imerode(b_one_region, se);
        % obtain the indices where skin is present
        [y_values x_values] = find(b_1);
        
        % call the polyfit which returns the coefficients for polynomial of
        % degree 5 that is best fit for data in y_values
        p = polyfit(x_values, y_values, 5);
        % call the polyval function that returns the value evaluated at
        % x_values
        y = polyval(p, x_values);
        % plot this curve line on original in blue color with width of 3
        plot(x_values, y,'b','Linewidth',3);
    end
    % providethe required output and pause after displaying result for each
    % image
end
% display the number of melons obtained
fprintf('The number of melons present are: %d\n',number_of_melons);
end