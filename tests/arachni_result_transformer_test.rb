require 'test/unit'
require 'json'
require_relative '../src/arachni_result_transformer'

class FakeUuidProvider
  def uuid
    '49bf7fd3-8512-4d73-a28f-608e493cd726'
  end
end

class ArachniResultTransformerTest < Test::Unit::TestCase

  def setup
    @transformer = ArachniResultTransformer.new(FakeUuidProvider.new)

    @empty_result = <<EOM
{
  "version" : "1.5.1",
  "seed" : "14b43fd42755e2c1dbf511707a08dda2",
  "options" : {
    "http" : {
      "user_agent" : "Arachni/v1.5.1",
      "request_timeout" : 10000,
      "request_redirect_limit" : 5,
      "request_concurrency" : 20,
      "request_queue_size" : 100,
      "request_headers" : {},
      "response_max_size" : 500000,
      "cookies" : {},
      "authentication_type" : "auto"
    },
    "scope" : {
      "redundant_path_patterns" : {},
      "dom_depth_limit" : 5,
      "exclude_file_extensions" : [],
      "exclude_path_patterns" : [],
      "exclude_content_patterns" : [],
      "include_path_patterns" : [],
      "restrict_paths" : [],
      "extend_paths" : [],
      "url_rewrites" : {}
    },
    "session" : {},
    "audit" : {
      "parameter_values" : true,
      "exclude_vector_patterns" : [],
      "include_vector_patterns" : [],
      "link_templates" : [],
      "links" : true,
      "forms" : true,
      "cookies" : true,
      "jsons" : true,
      "xmls" : true,
      "ui_forms" : true,
      "ui_inputs" : true
    },
    "input" : {
      "values" : {},
      "default_values" : {
        "name" : "arachni_name",
        "user" : "arachni_user",
        "usr" : "arachni_user",
        "pass" : "5543!%arachni_secret",
        "txt" : "arachni_text",
        "num" : "132",
        "amount" : "100",
        "mail" : "arachni@email.gr",
        "account" : "12",
        "id" : "1"
      },
      "without_defaults" : false,
      "force" : false
    },
    "datastore" : {
      "report_path" : null,
      "token" : "5d744c7d1da0f4165fb630e190d9cf5a"
    },
    "browser_cluster" : {
      "local_storage" : {},
      "wait_for_elements" : {},
      "pool_size" : 6,
      "job_timeout" : 10,
      "worker_time_to_live" : 100,
      "ignore_images" : false,
      "screen_width" : 1600,
      "screen_height" : 1200
    },
    "checks" : [
      "common_files",
      "origin_spoof_access_restriction_bypass",
      "common_directories",
      "backup_files",
      "backup_directories",
      "directory_listing",
      "backdoors",
      "insecure_cross_domain_policy_headers",
      "htaccess_limit",
      "localstart_asp",
      "common_admin_interfaces",
      "x_frame_options",
      "form_upload",
      "credit_card",
      "cookie_set_for_parent_domain",
      "http_only_cookies",
      "html_objects",
      "insecure_cookies",
      "cvs_svn_users",
      "private_ip",
      "mixed_resource",
      "captcha",
      "insecure_cors_policy",
      "hsts",
      "unencrypted_password_forms",
      "emails",
      "password_autocomplete",
      "ssn",
      "allowed_methods",
      "insecure_client_access_policy",
      "insecure_cross_domain_policy_access",
      "xst",
      "interesting_responses",
      "http_put",
      "webdav",
      "xss",
      "xss_path",
      "unvalidated_redirect",
      "xpath_injection",
      "xxe",
      "xss_tag",
      "sql_injection_timing",
      "sql_injection_differential",
      "ldap_injection",
      "unvalidated_redirect_dom",
      "trainer",
      "xss_event",
      "code_injection",
      "response_splitting",
      "xss_dom",
      "code_injection_php_input_wrapper",
      "csrf",
      "xss_dom_script_context",
      "no_sql_injection",
      "code_injection_timing",
      "file_inclusion",
      "source_code_disclosure",
      "os_cmd_injection",
      "session_fixation",
      "rfi",
      "no_sql_injection_differential",
      "os_cmd_injection_timing",
      "path_traversal",
      "sql_injection",
      "xss_script_context"
    ],
    "platforms" : [],
    "plugins" : {},
    "no_fingerprinting" : false,
    "authorized_by" : null,
    "url" : "http://192.168.178.111/"
  },
  "sitemap" : {},
  "start_datetime" : "2018-05-31 15:30:37 +0000",
  "finish_datetime" : "2018-05-31 15:30:40 +0000",
  "delta_time" : "00:00:03",
  "issues" : [],
  "plugins" : {}
}
EOM
  end

  def test_should_transform_a_empty_result_into_the_finding_format

    result = JSON.parse(@empty_result)

    assert_equal(
        @transformer.transform(result),
        []
    )
  end

  def test_add_a_timed_out_finding_when_optional_parameter_is_passed

    result = JSON.parse(@empty_result)

    assert_equal(
        @transformer.transform(result, timed_out: true),
        [{
             id: "49bf7fd3-8512-4d73-a28f-608e493cd726",
             name: "Arachni Scan timed out and could no be finished.",
             description: "Arachni Scan didnt send any new requests for 5 minutes. This probably means that arachni encountered some internal errors it could not handle.",
             osi_layer: 'NOT_APPLICABLE',
             severity: "MEDIUM",
             category: "ScanError",
             hint: "This could be related to a misconfiguration. But could also be related to internal instabilities of the arachni platform.",
             attributes: {}
         }]
    )
  end
end