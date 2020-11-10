#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Sort the order of projects' schemes.
# Usage: sort-schemes.sh

# Alias for replacing symbols.
aliasNewLine='@'
aliasNumber='%numberAlias%'

# Regex constants for position number.
regexStartPlaceNumber="<key>[a-zA-z -^#.]*<\/key>[${aliasNewLine}][[:space:]]*<dict>[${aliasNewLine}][[:space:]]*<key>orderHint<\/key>[${aliasNewLine}][[:space:]]*<integer>"
regexEndPlaceNumber="<\/integer>[${aliasNewLine}][[:space:]]*<\/dict>"

# Regex constants for hidden schemes.
regexHiddenScheme="<key>isShown<\/key><false\/>"
regexStartHiddenScheme="<key>[a-zA-z -^#.]*<\/key>[${aliasNewLine}][[:space:]]*<dict>[${aliasNewLine}][[:space:]]*"
regexEndHiddenScheme="<key>orderHint<\/key>[${aliasNewLine}][[:space:]]*<integer>[0-9]*<\/integer>[${aliasNewLine}][[:space:]]*<\/dict>"

# Scheme counter.
currentSchemeNumber=0

function replace_number_or_hide_scheme() {

  # Get parameters.
  local projectName=$1
  local isHidden=$2
  local isNotEnd=true

  # Build path to file of scheme.
  local fileName="${projectName}/xcuserdata/$USER.xcuserdatad/xcschemes/xcschememanagement.plist"

  # Prepare the backup file.
  local backupFile="${fileName}.bak"

  # Set the start of regex based on isHidden value.
  if $isHidden; then
    lastRegex=$regexStartHiddenScheme
  else
    lastRegex=$regexStartPlaceNumber
  fi

  # Check that the scheme file exists.
  if [ -f "$fileName" ]; then
    while $isNotEnd; do
      if $isHidden; then

        # Regex for search the place for hide the scheme.
        pattern="(${lastRegex})(${regexEndHiddenScheme})"

        # Regex for hidden scheme.
        replacePattern="\1$regexHiddenScheme\2"
      else

        # Regex for search the number of scheme.
        pattern="(${lastRegex})\d+(${regexEndPlaceNumber})"

        # Regex for replacing the number of scheme.
        replacePattern="\1${aliasNumber}${currentSchemeNumber}\2"
      fi

      # Replace new line to alias.
      tr '\n' "${aliasNewLine}" < "${fileName}" > "${backupFile}"
        
      # Replace number or hide the scheme.
      perl -i -pe "s/${pattern}/${replacePattern}/" "${backupFile}"

      # This is a fix to avoid problems with inserting number value via perl.
      perl -i -pe "s/${aliasNumber}//" "${backupFile}"
        
      # Replace new line alias to new line symbol.
      tr ${aliasNewLine} '\n' < "${backupFile}" > "${fileName}"

      # Build regex the for next scheme place.
      if $isHidden; then
        lastRegex="${lastRegex}${regexHiddenScheme}${regexEndHiddenScheme}${aliasNewLine}[[:space:]]*${regexStartHiddenScheme}"
      else
        lastRegex="${lastRegex}[0-9]*${regexEndPlaceNumber}${aliasNewLine}[[:space:]]*${regexStartPlaceNumber}"
      fi

      # Check that the file still has matches for the given regex.
      local countMatches=$(cat "${backupFile}" | grep -o "$lastRegex" | wc -l)
      if (( $countMatches < 1 )); then
        isNotEnd=false
      fi

      # Increase schemes number 
      currentSchemeNumber=$((currentSchemeNumber+1))

      # Remove backup file.
      rm "${backupFile}"
    done
  else
    echo "The schemes configuration does not exist for the project ${projectName}."
  fi
}

# Sort scheme in the AppCenter.xcworkspace project.
replace_number_or_hide_scheme "AppCenter.xcworkspace" false

# Sort schemes in modules projects.
replace_number_or_hide_scheme "AppCenter/AppCenter.xcodeproj" false
replace_number_or_hide_scheme "AppCenterAnalytics/AppCenterAnalytics.xcodeproj" false
replace_number_or_hide_scheme "AppCenterCrashes/AppCenterCrashes.xcodeproj" false
replace_number_or_hide_scheme "AppCenterDistribute/AppCenterDistribute.xcodeproj" false

# Sort schemes in apps projects.
replace_number_or_hide_scheme "Sasquatch/Sasquatch.xcodeproj" false
replace_number_or_hide_scheme "SasquatchMac/SasquatchMac.xcodeproj" false
replace_number_or_hide_scheme "SasquatchTV/SasquatchTV.xcodeproj" false

# Sort other schemes.
replace_number_or_hide_scheme "CrashLib/CrashLib.xcodeproj" false
replace_number_or_hide_scheme "Vendor/PLCrashReporter/CrashReporter.xcodeproj" false
replace_number_or_hide_scheme "Vendor/OCMock/Source/OCMock.xcodeproj" true
replace_number_or_hide_scheme "Vendor/OCHamcrest/Source/OCHamcrest.xcodeproj" true
