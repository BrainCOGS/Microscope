
load('zemax_results.mat')

angles = -10:0.5:10;

fieldCurvature =  zeros(length(angles), 2);
FWHM_radial    =  zeros(length(angles), 2);
FWHM_axial     =  zeros(length(angles), 2);

for angle_idx = 1:length(angles)

    PSF = reshape(export.results(angle_idx,:,:,:),32,32,401).^2; % Square for 2p PSF

    zProfile = max(max(PSF,[],1),[],2);
    zProfile = zProfile(:);

    [maxValue, peak_z] = max(zProfile);

    fieldCurvature(angle_idx, 1) = angles(angle_idx);
    fieldCurvature(angle_idx, 2) = peak_z * export.resolutionDz;

    halfMax = maxValue/2;

    % Find FWHM axial
    width = sum( zProfile > halfMax) * export.resolutionDz;
    FWHM_axial(angle_idx, 1) = angles(angle_idx);
    FWHM_axial(angle_idx, 2) = width;

    % Find FWHM in radial / xy 
    slice = PSF(:,:,peak_z);
    psfArea = sum( slice(:) >= halfMax );
    width = 2*sqrt(psfArea/3.1415) * export.resolutionDx  ;
    FWHM_radial(angle_idx, 1) = angles(angle_idx);
    FWHM_radial(angle_idx, 2) = width;
end

figure(1),clf;

subplot(3,1,1)
errorbar(fieldCurvature(:,1), fieldCurvature(:,2)-20.2,  export.resolutionDz, 'bo', 'MarkerFaceColor', 'b')
% Keep in mind that fieldCurvature(:,2) is computed from the distance to the last element in the zemax path, which is above the focal plane. If the PSF moves up along the z axis, then the values will become smaller. Maybe it's better to flip the y-axis for this one. Note sure...
hold on;
plot([-10,10], [0, 0], 'k--')
title("Field Curvature")
xlabel("Angle [deg]")
ylabel("Axial peak position [\mu m]")
ylim([-1.1,1.1])
xlim([-11, 11])

subplot(3,1,2)
errorbar(FWHM_radial(:,1), FWHM_radial(:,2), export.resolutionDx, 'bo', 'MarkerFaceColor', 'b')
hold on;
plot([-10,10], [0.75, 0.75], 'k--')
title("Radial FWHM")
xlabel("Angle [deg]")
ylabel("FWHM radial [\mu m], line at 750nm")
ylim([0, 2.5])
xlim([-11, 11])

subplot(3,1,3)
errorbar(FWHM_axial(:,1), FWHM_axial(:,2), export.resolutionDz, 'bo', 'MarkerFaceColor', 'b')
hold on;
plot([-10,10], [5.0, 5.0], 'k--')
title("Axial FWHM")
xlabel("Angle [deg]")
ylabel("FWHM Axial [\mu m], line at 4.5\mu m")
ylim([0, 10])
xlim([-11, 11])



%% Plot the center PSF as example and for comparison

angle_idx = 19;
PSF = reshape(export.results(angle_idx,:,:,:),32,32,401).^2; % Square for 2p PSF

zProfile = max(max(PSF,[],1),[],2); % max over x and y
zProfile = zProfile(:);
[~, peak_z] = max(zProfile);
XYslice = PSF(:,:,peak_z);

yProfile = max(max(PSF,[],3),[],1); %max over z and x
[~, peak_y] = max(yProfile);
XZslice = reshape(PSF(:,peak_y,:),32, 401)';

figure(2)
subplot(1,2,1)
imagesc((-16:15)*export.resolutionDx, (-16:15)*export.resolutionDy, XYslice )
title('xy')
daspect([1 1 1])
xlim([-1.1, 1.1])
ylim([-1.1, 1.1])
xlabel("\mu  m")
ylabel("\mu m")
title("Radial")

subplot(1,2,2)
imagesc((-16:15)*export.resolutionDx, (1:401)*export.resolutionDz, XZslice)
title('xz')
daspect([1 1 1])

figure(22)
XYslice = PSF(:,:,peak_z-70);
imagesc((-16:15)*export.resolutionDx, (-16:15)*export.resolutionDy, XYslice )
title('xy')
daspect([1 1 1])
xlim([-1.1, 1.1])
ylim([-1.1, 1.1])
xlabel("\mu  m")
ylabel("\mu m")
title("Radial, 7mu above")
caxis([0,0.01])

%%

figure(2222),clf;

s = isosurface(PSF, 0.9);
p = patch(s);
set(p,'FaceColor', [1.0, 1.0, 0.1]);  
set(p,'FaceAlpha', 1)
set(p,'EdgeColor','none');
camlight;
lighting gouraud;

% s = isosurface(PSF, 0.75);
% p = patch(s);
% set(p,'FaceColor', [0.8,0.8,0.2]);  
% set(p,'FaceAlpha', 0.4)
% set(p,'EdgeColor','none');
% camlight;
% lighting gouraud;

s = isosurface(PSF, 0.25);
p = patch(s);
set(p,'FaceColor', [0.0,0.7,0.7]);  
set(p,'FaceAlpha', 0.2)
set(p,'EdgeColor','none');
camlight;
lighting gouraud;

s = isosurface(PSF, 0.005);
p = patch(s);
set(p,'FaceColor', [0.2,0.5,1.0]);  
set(p,'FaceAlpha', 0.1)
set(p,'EdgeColor','none');
camlight;
lighting gouraud;

daspect([1 1 1])
zlim([1,401])
xlim([1,32])
ylim([1,32])
view([60,60]);

saveas(gcf,'PSF_transparent.pdf')
%% Range

counter = 1;

plot_idx = 1:2:41;

figure(3),clf;
for angle_idx = plot_idx
    
    PSF = reshape(export.results(angle_idx,:,:,:),32,32,401).^2;
    
    zProfile = max(max(PSF,[],1),[],2); % max over x and y
    zProfile = zProfile(:);
    [~, peak_z] = max(zProfile);
    XYslice = PSF(:,:,peak_z);
    
    yProfile = max(max(PSF,[],3),[],1); %max over z and x
    [~, peak_y] = max(yProfile);
    XZslice = reshape(PSF(:,peak_y,:),32, 401)';

    subplot(1, length(plot_idx), counter)
    imagesc((-16:15)*export.resolutionDx, (1:401)*export.resolutionDz, XZslice)
    % title(angles(angle_idx))
    ylim([10,30])
    daspect([1 1 1])
    counter = counter + 1;
    set(gca, 'color', 'none');
    set(gca,'xtick',[])
    set(gca,'ytick',[])

end


