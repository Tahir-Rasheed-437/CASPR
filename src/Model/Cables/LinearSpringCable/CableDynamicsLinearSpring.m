classdef CableDynamicsLinearSpring < CableDynamics
    %CABLEKINEMATICS Summary of this class goes here
    %   Detailed explanation goes here
    properties        
        actuatorForceMin
        actuatorForceMax
    end
        
    methods 
        function cd = CableDynamicsLinearSpring(name)
            cd@CableDynamics(name);
        end
        
        function update(obj, cableKinematics, bodyKinematics)
            update@CableDynamics(obj, cableKinematics, bodyKinematics);
        end
    end
    
    methods (Static)
        function c = LoadXmlObj(xmlobj)
            name = char(xmlobj.getAttribute('name'));
            c = CableDynamicsIdeal(name);
            
            propertiesObj = xmlobj.getElementsByTagName('properties').item(0);
            
            c.K = str2double(propertiesObj.getElementsByTagName('K').item(0).getFirstChild.getData);
            c.forceMin = str2double(propertiesObj.getElementsByTagName('force_min').item(0).getFirstChild.getData);
            c.forceMax = str2double(propertiesObj.getElementsByTagName('force_max').item(0).getFirstChild.getData);
            c.forceInvalid = str2double(propertiesObj.getElementsByTagName('force_error').item(0).getFirstChild.getData);
        end
    end
end
