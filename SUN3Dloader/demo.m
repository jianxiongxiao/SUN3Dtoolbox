%% this code demonstrates how to load SUN3D and how to use SUN3D in different ways

data = loadSUN3D('hotel_umd/maryland_hotel3');

%% for each frame, show the frame and point cloud, as well as the annotation if there is any
for frameID=1:length(data.image)
    image = imread(data.image{frameID});
    depth = depthRead(data.depth{frameID});
    
    XYZcamera = depth2XYZcamera(data.K, depth);
    
    % pick the valid points with their color
    valid = logical(XYZcamera(:,:,4));  valid = valid(:)';
    XYZ = reshape(XYZcamera,[],4)';
    RGB = reshape(image,[],3)';
    XYZ = XYZ(1:3,valid);
    RGB = RGB(:,valid);    
    % plot in camera coordinate
    % visualizePointCloud(XYZ,RGB); disp('check the point cloud.'); pause;
    
    % transform to world coordinate
    XYZworld = transformPointCloud(XYZ,data.extrinsicsC2W(:,:,frameID));
    
    if frameID==1; clf; end
    
    subplot(1,2,1);
    hold off;
    imshow(image);
    title(sprintf('Image and Annotation for Frame %d',frameID));
    
    % draw the annotation if the frame is a keyframe
    [~,fname]=fileparts(data.image{frameID});
    keyframeID = find(ismember(cellstr(data.annotation.fileList), [fname '.jpg']));
    
    if ~isempty(keyframeID)
        if ~isempty(data.annotation.frames{keyframeID})
            hold on
            
            for polygonID = 1:length(data.annotation.frames{keyframeID}.polygon)
                
                X = data.annotation.frames{keyframeID}.polygon{polygonID}.x;
                Y = data.annotation.frames{keyframeID}.polygon{polygonID}.y;
                objectID = data.annotation.frames{keyframeID}.polygon{polygonID}.object;
                LineWidth = 4;
                color = ObjectColor(objectID);
                plot([X X(1)],[Y Y(1)], 'LineWidth', LineWidth, 'Color', [0 0 0]); hold on;                
                plot([X X(1)],[Y Y(1)], 'LineWidth', LineWidth/2, 'Color', color); hold on;
                xx = mean(X);
                yy = mean(Y);
                ht=text(xx,yy, data.annotation.objects{objectID+1}.name, 'horizontalAlignment', 'center', 'verticalAlignment', 'bottom');
                set(ht, 'color', color, 'fontsize', 10);
            end
        end
    end
    
    % plot in world coordinate
    subplot(1,2,2)
    visualizePointCloud(XYZworld,RGB,10); hold on;
    title(sprintf('World Coordinate using Frame 1-%d',frameID));
    
    disp('check the point cloud, and press any key to continue.'); pause;
end

%% for each object, find all key frame with the object annotated, and plot the point cloud
for objectID=1:length(data.annotation.objects)
    if ~isempty(data.annotation.objects{objectID})
        figure(objectID);
        XYZobject = [];
        RGBobject = [];
        cnt = 0;
        
        for frameID=1:length(data.image)
            [~,fname]=fileparts(data.image{frameID});
            keyframeID = find(ismember(cellstr(data.annotation.fileList), [fname '.jpg']));
            if ~isempty(keyframeID)
                if ~isempty(data.annotation.frames{keyframeID})   
                    for polygonID = 1:length(data.annotation.frames{keyframeID}.polygon)
                        objectIDnow = data.annotation.frames{keyframeID}.polygon{polygonID}.object+1; % javascript need +1
                        if objectID==objectIDnow
                            
                            X = data.annotation.frames{keyframeID}.polygon{polygonID}.x;
                            Y = data.annotation.frames{keyframeID}.polygon{polygonID}.y;
                            BW = poly2mask(X, Y, 480, 640);
                            
                            image = imread(data.image{frameID});
                            depth = depthRead(data.depth{frameID});

                            XYZcamera = depth2XYZcamera(data.K, depth);

                            % pick the valid points with their color
                            valid = logical(XYZcamera(:,:,4)) & BW;  valid = valid(:)';
                            XYZ = reshape(XYZcamera,[],4)';
                            RGB = reshape(image,[],3)';
                            XYZ = XYZ(1:3,valid);
                            RGB = RGB(:,valid);    
                            % transform to world coordinate
                            XYZworld = transformPointCloud(XYZ,data.extrinsicsC2W(:,:,frameID));          
                            
                            XYZobject = [XYZobject XYZworld];
                            RGBobject = [RGBobject RGB];
                            
                            subplot(4,6,1);
                            visualizePointCloud(XYZobject,RGBobject);
                            grid off
                            
                            cnt = cnt + 1;
                            
                            if (cnt<=4*6)
                                subplot(4,6,cnt+1);
                                imshow(image);
                                hold on
                                color = ObjectColor(objectID-1); % to match javascript color
                                LineWidth = 4;
                                plot([X X(1)],[Y Y(1)], 'LineWidth', LineWidth, 'Color', [0 0 0]); hold on;                
                                plot([X X(1)],[Y Y(1)], 'LineWidth', LineWidth/2, 'Color', color); hold on;
                                xx = mean(X);
                                yy = mean(Y);
                                ht=text(xx,yy, data.annotation.objects{objectID+1}.name, 'horizontalAlignment', 'center', 'verticalAlignment', 'bottom');
                                set(ht, 'color', color, 'fontsize', 10);   
                            end
                        end
                    end
                end
            end
        end
    end
end
