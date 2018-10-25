function Current = GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end

Time = str2double(get(handles.TimeValue,'String'));

Data = handles.CurrentData;
data = Data.(Source);
data = data(:,:,:,Time);

switch View{get(handles.ViewPop,'Value')}
    case 'Axial';  Current = permute(data,[1 2 3 4 5]);
    case 'Coronal';  Current = permute(data,[1 3 2 4 5]);
    case 'Sagittal';  Current = permute(data,[3 2 1 4 5]);
end
Current = rot90(Current);
