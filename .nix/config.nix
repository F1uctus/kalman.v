{
  ## DO NOT CHANGE THIS
  format = "1.0.0";
  ## unless you made an automated or manual update
  ## to another supported format.

  attribute = "kalman";
  no-rocq-yet = true;

  default-bundle = "rocq-9.3";

  bundles =
    let
      common-coq = {
        coq.override.version = "9.3";
        stdlib.job = true;
        bignums.job = true;
      };
    in
    {
      "rocq-9.3" = {
        rocqPackages = {
          rocq-core.override.version = "9.3";
        };
        coqPackages = common-coq;
        push-branches = [ "main" ];
      };
    };

  cachix.f1uctus.authToken = "CACHIX_AUTH_TOKEN";
  cachix.coq = {};
  cachix.math-comp = {};
  cachix.coq-community = {};
}
