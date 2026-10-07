@{
    Severity = @('Error','Warning')
    Rules = @{ PSUseCompatibleSyntax = @{ Enable = $true; TargetVersions = @('5.1') } }
    # Console output is intentional for the interactive administrator menu.
    # Script parameters are consumed by the nested main function through script scope;
    # the unused-parameter rule does not follow that scope (or serialized worker helpers).
    ExcludeRules = @('PSAvoidUsingWriteHost','PSReviewUnusedParameter')
}
