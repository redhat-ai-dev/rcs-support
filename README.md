# Road-Core/Service Sidecar Setup

## Requirements

- [yq](https://github.com/mikefarah/yq/) v4 and above.
- Access to a Kubernetes (or OCP) cluster with permissions to edit CRs and apply resources to namespaces.

## Reliability

This setup script was tested with [Red Hat Developer Hub (RHDH) v1.4](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/) and its [supported OCP versions](https://access.redhat.com/support/policy/updates/developerhub):

- v4.14
- v4.15
- v4.16
- v4.17

## Usage

### Step 1

To generate your own local copy of:
1. [rcsconfig.yaml](./templates/skeleton/rcsconfig.yaml)
2. [rcssecret.yaml](./templates/skeleton/rcssecret.yaml)

Run:

```
bash ./scripts/generate-resources.sh
```

To obtain your own local copy of the required environment variable file:
1. Navigate to [/env](./env/)
2. Copy [default-values](./env/default-values) to a new file called `values`

### Step 2

There are 3 different ways you can use this setup script.

1. [Defining LLM providers inside rcsconfig.yaml itself](#llm-providers-only-in-rcsconfigyaml)
2. [Passing LLM providers from Red Hat Developer Hub (RHDH) configuration files to road-core **and** defining other LLM providers inside rcsconfig.yaml](#llm-providers-in-rhdh-config--rcsconfigyaml)
3. [**Only** passing LLM providers from RHDH configuration files to road-core](#llm-providers-only-in-rhdh-config)


#### LLM Providers Only In rcsconfig.yaml

When first generated, `rcsconfig.yaml` will look like the following:
```
llm_providers:
  - name: dummy
    type: openai
    url: https://dummy.com
    models:
      - name: dummymodel
  - name: <cluster-name>
    type: openai
    url: <https://my-model-url/v1>
    credentials_path: config/provider-keys/<key.txt>
    disable_model_check: true
ols_config:
  conversation_cache:
    type: memory
    memory:
      max_entries: 1000
  authentication_config:
    module: "noop"
  default_provider: dummy
  default_model: dummymodel
  query_validation_method: llm
dev_config:
  enable_dev_ui: false
  disable_auth: false
  disable_tls: true
  enable_system_prompt_override: true
```

**query_validation_method** section is recommended to be set as **llm** to enable question validation. If you want to turn off the validation, set to **disabled**

You only need to edit the **llm_providers** section of this file. Due to restrictions by road-core/service we **must** keep the dummy provider defined, as well as having the dummy provider + model as the default.

For example if I have a provider I wish to add with the following information:
- Url: https://my-example-url.com:8080
- Token: my-example-token

I would add it to the file and have the following result:

```
llm_providers:
  - name: dummy
    type: openai
    url: https://dummy.com
    models:
      - name: dummymodel
  - name: example-name
    type: openai
    url: https://my-example-url.com:8080/v1
    credentials_path: config/provider-keys/example.txt
    disable_model_check: true
ols_config:
  conversation_cache:
    type: memory
    memory:
      max_entries: 1000
  authentication_config:
    module: "noop"
  default_provider: dummy
  default_model: dummymodel
  query_validation_method: llm
dev_config:
  enable_dev_ui: false
  disable_auth: false
  disable_tls: true
  enable_system_prompt_override: true
```

For the purpose of this example I named my provider **example-name**, this name can be anything you want it to be. Keep note of it as it will be the provider name you pass when hitting RCS endpoints.

Additionally, you may notice that `credentials_path` was populated with `config/provider-keys/example.txt`. All provider keys will be added to the generated `rcssecrets.yaml` file created in [Step 1](#step-1).

You can view the contents of that file for this example below:

```
kind: Secret
apiVersion: v1
metadata:
 name: provider-keys
type: Opaque
stringData:
 example.txt: my-example-token
```

After these two files have been populated you will need to add the appropriate information to your `values` file generated in [Step 1](#step-1). There are instructions within that file for obtaining the necessary info.

#### LLM Providers In RHDH Config & rcsconfig.yaml

To utilize both RHDH Config loading of LLM providers as well as defining them in `rcsconfig.yaml` you will follow the same steps as above in [LLM Providers Only In rcsconfig.yaml](#llm-providers-only-in-rcsconfigyaml). The only thing that will change is ensuring `USE_RHDH_CONFIG` is set to `true` and it's required environment variables are also set in your `values` file.

#### LLM Providers Only In RHDH Config

When first generated, `rcsconfig.yaml` will look like the following:
```
llm_providers:
  - name: dummy
    type: openai
    url: https://dummy.com
    models:
      - name: dummymodel
  - name: <cluster-name>
    type: openai
    url: <https://my-model-url/v1>
    credentials_path: config/provider-keys/<key.txt>
    disable_model_check: true
ols_config:
  conversation_cache:
    type: memory
    memory:
      max_entries: 1000
  authentication_config:
    module: "noop"
  default_provider: dummy
  default_model: dummymodel
  query_validation_method: llm
dev_config:
  enable_dev_ui: false
  disable_auth: false
  disable_tls: true
  enable_system_prompt_override: true
```

**query_validation_method** section is recommended to be set as **llm** to enable question validation. If you want to turn off the validation, set this value to **disabled**. Or you can set **questionValidation** in RHDH lightspeed config.

If you intend on only obtaining LLM provider information from your RHDH config you don't need to set anything in `rcsconfig.yaml`. You will however need to *remove* the templated cluster information.

You should have an `rcsconfig.yaml` file that looks like the following after the removal:

```
llm_providers:
  - name: dummy
    type: openai
    url: https://dummy.com
    models:
      - name: dummymodel
ols_config:
  conversation_cache:
    type: memory
    memory:
      max_entries: 1000
  authentication_config:
    module: "noop"
  default_provider: dummy
  default_model: dummymodel
  query_validation_method: llm
dev_config:
  enable_dev_ui: false
  disable_auth: false
  disable_tls: true
  enable_system_prompt_override: true
```

As for the `rcssecret.yaml` file, you are free to leave that unedited as it won't be used.

Before moving to the next step you will need to ensure all environment variables are set in your `values` file.

### Step 3

To add the sidecar to your Red Hat Developer Hub (RHDH) Pod, first ensure you are logged into your cluster and then run:
```
bash ./setup-sidecar.sh
```

## Examples

You can view the following example use-cases below:

- [Single LLM Provider](./examples/single-provider/)
- [Multiple LLM Providers](./examples/multi-provider/)
- [RHDH Config Env Enabled](./examples/rhdh-config-enabled/)
