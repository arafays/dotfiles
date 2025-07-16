# Design Document

## Overview

The script cleanup system will systematically audit, analyze, and clean up the scripts directory in the dotfiles repository. Based on research, there are approximately 45+ scripts in the `.local/share/bin/` directory, many of which contain references to the HyDE project that was previously removed. The system will identify obsolete scripts, update salvageable ones, and organize the remaining scripts for better maintainability.

## Architecture

The cleanup system follows a multi-phase approach:

1. **Discovery Phase**: Scan and catalog all scripts
2. **Analysis Phase**: Analyze dependencies, usage, and Hyde references
3. **Classification Phase**: Categorize scripts by status and action needed
4. **Action Phase**: Remove, update, or preserve scripts based on classification
5. **Organization Phase**: Restructure remaining scripts logically
6. **Documentation Phase**: Update documentation to reflect changes

## Components and Interfaces

### Script Scanner Component

**Purpose**: Discover and catalog all scripts in the repository

**Interface**:
- Input: Scripts directory path
- Output: List of script files with metadata (permissions, size, type)

**Implementation**:
- Recursively scan `scripts/` directory
- Identify executable files and shell scripts
- Extract basic metadata for each script

### Hyde Reference Analyzer

**Purpose**: Identify and analyze Hyde-related references in scripts

**Interface**:
- Input: Script file path
- Output: Hyde reference report (variables, paths, dependencies)

**Implementation**:
- Search for Hyde-specific patterns:
  - `hydeTheme`, `hydeThemeDir`, `hydeConfDir` variables
  - `/hyde/` or `/.hyde/` path references
  - HyDE-specific configuration file references
- Categorize references as critical or non-critical

### Usage Detector Component

**Purpose**: Determine which scripts are actively used by current configurations

**Interface**:
- Input: Script name/path
- Output: Usage status (active, referenced, unused)

**Implementation**:
- Scan Hyprland configuration files for script references
- Check waybar configuration for script calls
- Analyze keybinding configurations
- Verify PATH accessibility for bin scripts

### Script Classifier

**Purpose**: Categorize scripts based on analysis results

**Interface**:
- Input: Script analysis data
- Output: Classification (remove, update, preserve, organize)

**Classifications**:
- **REMOVE**: Scripts with critical Hyde dependencies and no current usage
- **UPDATE**: Scripts with fixable Hyde references but useful functionality
- **PRESERVE**: Scripts actively used without Hyde dependencies
- **ORGANIZE**: Scripts that need better categorization or location

### Script Updater Component

**Purpose**: Update scripts to remove Hyde dependencies while preserving functionality

**Interface**:
- Input: Script file and update instructions
- Output: Updated script file

**Implementation**:
- Remove or replace Hyde variable references
- Update hardcoded Hyde paths
- Preserve core functionality
- Add comments documenting changes

## Data Models

### Script Metadata Model
```bash
ScriptInfo {
    path: string
    name: string
    type: string (shell, python, executable)
    permissions: string
    size: number
    last_modified: timestamp
}
```

### Hyde Reference Model
```bash
HydeReference {
    script_path: string
    reference_type: string (variable, path, config)
    line_number: number
    content: string
    criticality: string (critical, non-critical)
}
```

### Usage Analysis Model
```bash
UsageStatus {
    script_path: string
    is_referenced: boolean
    referenced_by: array[string]
    is_executable: boolean
    usage_frequency: string (active, occasional, unused)
}
```

### Classification Model
```bash
ScriptClassification {
    script_path: string
    action: string (remove, update, preserve, organize)
    reason: string
    dependencies: array[string]
    update_instructions: string
}
```

## Error Handling

### File Access Errors
- Handle permission denied errors gracefully
- Skip inaccessible files with logging
- Continue processing other scripts

### Analysis Errors
- Log scripts that cannot be parsed
- Handle binary files appropriately
- Provide fallback classification for problematic scripts

### Update Errors
- Create backups before modifying scripts
- Rollback changes if updates fail
- Validate script syntax after updates

## Testing Strategy

### Unit Testing
- Test each component independently
- Mock file system operations for consistent testing
- Verify pattern matching accuracy for Hyde references

### Integration Testing
- Test complete workflow from discovery to cleanup
- Verify configuration file updates work correctly
- Test rollback mechanisms

### Validation Testing
- Verify updated scripts maintain functionality
- Test that removed scripts don't break configurations
- Confirm PATH and permissions are preserved

### Manual Testing
- Test key scripts manually after updates
- Verify Hyprland and waybar functionality
- Check that commonly used utilities still work

## Implementation Phases

### Phase 1: Discovery and Analysis
- Implement script scanner
- Build Hyde reference analyzer
- Create usage detector
- Generate comprehensive audit report

### Phase 2: Classification and Planning
- Implement script classifier
- Generate action plan for each script
- Create backup strategy
- Prepare update templates

### Phase 3: Cleanup Execution
- Remove obsolete scripts
- Update salvageable scripts
- Preserve functional scripts
- Update configuration references

### Phase 4: Organization and Documentation
- Reorganize remaining scripts logically
- Update PATH configurations if needed
- Update LLM-CONTEXT.md documentation
- Create cleanup summary report

## Key Design Decisions

### Backup Strategy
- Create timestamped backup of entire scripts directory before cleanup
- Individual script backups before updates
- Rollback capability for failed operations

### Hyde Reference Handling
- Prioritize removing references to non-existent Hyde directories
- Preserve functionality where possible by replacing with generic alternatives
- Document all changes made to scripts

### Configuration Integration
- Automatically update configuration files that reference removed scripts
- Preserve functionality by suggesting alternatives where needed
- Maintain compatibility with both KDE and Hyprland environments

### Script Organization
- Group related scripts by functionality (system, media, wallpaper, etc.)
- Maintain executable permissions and PATH accessibility
- Use consistent naming conventions for better maintainability