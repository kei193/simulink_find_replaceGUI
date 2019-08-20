% FindAndReplaceModelGUI script
%
% Find and Replace GUI for Simulink.
%   This GUI allows for Find and Replace functionality
%   In a standard Simulink model, using the FindGUI class.
%
%   * Finds blocks and lines containing search words and highlights them.
%   * Allows to step forward or back through the found items
%   * Allows text replace of the current item or all found items
%
% To use the GUI:
%    1. Open a Simulink model
%    2. Run this script.
%
% P.S. MathWorks - How is it even possible that this isn't a
% built-in function after over 25 years?

% Start GUI
FindGUI.start();