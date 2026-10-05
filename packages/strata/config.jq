# Build the launch plan from the saved run config and shared API settings.
# CLI overrides arrive as strings; an empty string means "keep the saved value".
# The Nix wrapper supplies $package_source. Nothing here reads model weights.

def engine_option($flag):
  (.args | index($flag)) as $index
  | if $index == null then null else .args[$index + 1] end;

def set_engine_option($flag; $value):
  (.args | index($flag)) as $index
  | if $index == null then
      .args += [$flag, $value]
    else
      .args[$index + 1] = $value
    end;

def is_whole_number:
  if type == "number" then . == floor else false end;

def validate_structure:
  if type != "object" then
    error("run config must be a JSON object")
  elif (.args | type) != "array" or (.args | all(type == "string") | not) then
    error("run config args must be an array of strings")
  elif ($shared | length) != 1 or ($shared[0] | type) != "object" then
    error("shared settings must contain one JSON object")
  elif (.vision // false) or (.backend // "cuda") != "cuda" then
    error("this package supports text-only CUDA configs")
  else
    .
  end;

def context_limit:
  if $context_override != "" then
    $context_override | tonumber
  elif (.args | index("--max-context")) != null then
    engine_option("--max-context") | tonumber
  else
    131072
  end;

def thinking_budget($context):
  if $thinking_override != "" then
    $thinking_override | tonumber
  elif has("reasoning_budget_tokens") then
    # Preserve a deliberately disabled cap: both 0 and null mean uncapped.
    .reasoning_budget_tokens
  else
    [65536, ($context / 2 | floor)] | min
  end;

def output_limit($settings; $context):
  if $output_override != "" then
    $output_override | tonumber
  elif $settings | has("max_tokens") then
    $settings.max_tokens
  else
    [98304, ([1, ($context * 3 / 4 | floor)] | max)] | min
  end;

def api_port:
  if $port_override != "" then $port_override | tonumber else .port // 8081 end;

def validate_limits($context; $thinking; $output; $port):
  if ($context | is_whole_number | not) or $context < 1 or $context > 262144 then
    error("context must be a whole number between 1 and 262144")
  elif $thinking != null and
       (($thinking | is_whole_number | not) or $thinking < 0 or $thinking >= $context) then
    error("thinking budget must be nonnegative and smaller than context; 0 disables the cap")
  elif $output != null and
       (($output | is_whole_number | not) or $output < 1 or $output > $context) then
    error("output limit must be positive and no greater than context")
  elif $thinking != null and $thinking > 0 and $output != null and $thinking >= $output then
    error("thinking budget leaves no answer room; raise output or reduce thinking")
  elif ($port | is_whole_number | not) or $port < 1 or $port > 65535 then
    error("API port must be a whole number between 1 and 65535")
  else
    .
  end;

# Since Strata 0.1.40, resident CPU experts work with the existing GPU split.
# Keep only experts absent from every GPU cache in RAM, not the full arena.
def use_resident_experts:
  .args |= (map(select(. != "--mmap-experts" and . != "--resident-experts")) + ["--resident-experts"])
  | .env.STRATA_RESIDENT_HEADROOM_GIB //= "8";

def bind_nix_resources:
  .exe = ($package_source + "/engine/strata")
  | .lib_dirs = []
  | .cwd //= $config_directory;

def rebind_bundled_profile:
  (.args | index("--expert-profile")) as $index
  | if $index == null then
      .
    else
      .args[$index + 1] as $profile
      # Only replace bundled profiles, not the user's calibrated profile.
      | if $profile | test("^(/nix/store/.*/|)data/expert-profile(-coder)?\\.bin$") then
          set_engine_option(
            "--expert-profile";
            $package_source + "/data/" + ($profile | split("/") | last)
          )
        else
          .
        end
    end;

# Resolve and validate everything before the shell launcher writes either file.
validate_structure
| context_limit as $context
| thinking_budget($context) as $thinking
| output_limit($shared[0]; $context) as $output
| api_port as $port
| validate_limits($context; $thinking; $output; $port)
| bind_nix_resources
| .port = $port
| .reasoning_budget_tokens = $thinking
| set_engine_option("--max-context"; $context | tostring)
| rebind_bundled_profile
| use_resident_experts
| {
    config: .,
    shared: ($shared[0] + {max_tokens: $output})
  }
