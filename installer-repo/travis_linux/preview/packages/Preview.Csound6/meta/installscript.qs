function Component()
{
    gui.pageById(QInstaller.ComponentSelection).entered.connect(this, this.componentSelectionPageEntered);
}

Component.prototype.componentSelectionPageEntered = function()
{
   

    component.valueChanged.connect( this, this.reactOnChecked );
    
}

Component.prototype.reactOnChecked = function(key, value)
    {
      var otherPackage = installer.componentByName("CsoundCore.Csound6");
      
      if (otherPackage.installationRequested() && component.installationRequested())
      {
         var result = QMessageBox["question"]("test.deselect", "Installer", "There is a package already selected to be installed in the same directory as " + component.displayName + ".<br>" + "Do you want to deselect " + otherPackage.displayName + "?", QMessageBox.Ok | QMessageBox.Cancel);
         if (result == QMessageBox.Ok) 
         {
           gui.currentPageWidget().deselectComponent(otherPackage.name);

         }
         else
         {
            gui.currentPageWidget().deselectComponent(component.name);
         }
        
      }

      
      if (otherPackage.installed && component.installationRequested())
      {
         var result = QMessageBox["warning"]("test.uninstall", "Installer", "Please uninstall " + otherPackage.displayName + " before trying to install " + component.displayName +  ".<br>", QMessageBox.Ok );
         gui.currentPageWidget().deselectComponent(component.name);


      }

    }
   

