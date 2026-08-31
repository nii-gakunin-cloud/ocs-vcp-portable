# vcc コマンド一覧

## `vcc clear-processing`

```text
usage: vcc clear-processing [-h] vcid unit_name

Clear VCUnit processing state

positional arguments:
  vcid
  unit_name

options:
  -h, --help  show this help message and exit
```

## `vcc init-occtr`

```text
usage: vcc init-occtr [-h] [--consul_base_url CONSUL_BASE_URL] [--base_registry_address BASE_REGISTRY_ADDRESS]

Initialize VC Controller

options:
  -h, --help            show this help message and exit
  --consul_base_url CONSUL_BASE_URL
                        Base URL for Consul (default: http://127.0.0.1:8500/v1/)
  --base_registry_address BASE_REGISTRY_ADDRESS
                        Address of the user registry for VCP (default: None -> means `<vcc ip>:5000`)
```

## `vcc node-state`

### `vcc node-state get`

```text
usage: vcc node-state get [-h] vcid unit_name node_id

Get VcNode info

positional arguments:
  vcid
  unit_name
  node_id

options:
  -h, --help  show this help message and exit
```

### `vcc node-state set`

```text
usage: vcc node-state set [-h] vcid unit_name node_id state

Set VcNode info

positional arguments:
  vcid
  unit_name
  node_id
  state       Node state to set (e.g., RUNNING, STOPPED, etc.)

options:
  -h, --help  show this help message and exit
```

## `vcc vpncatalog`

### `vcc vpncatalog get`

```text
usage: vcc vpncatalog get [-h]

Get current VPN catalog config

options:
  -h, --help  show this help message and exit
```

### `vcc vpncatalog set`

```text
usage: vcc vpncatalog set [-h] [-p PATH]

Update VPN catalog config

options:
  -h, --help            show this help message and exit
  -p PATH, --path PATH  Path to the VPN catalog YAML file
```

## `vcc user`

### `vcc user add`

```text
usage: vcc user add [-h] user_name user_role

Add a user with a role (REGULAR or SUPER)

positional arguments:
  user_name
  user_role

options:
  -h, --help  show this help message and exit
```

### `vcc user modify`

```text
usage: vcc user modify [-h] user_name user_role

Modify a user's role

positional arguments:
  user_name
  user_role

options:
  -h, --help  show this help message and exit
```

### `vcc user check`

```text
usage: vcc user check [-h] user_name

Check if a user exists and get their info

positional arguments:
  user_name

options:
  -h, --help  show this help message and exit
```

### `vcc user list`

```text
usage: vcc user list [-h]

List all users and their info

options:
  -h, --help  show this help message and exit
```

## `vcc token`

### `vcc token create`

```text
usage: vcc token create [-h] [user_name]

Create new token

positional arguments:
  user_name

options:
  -h, --help  show this help message and exit
```

### `vcc token check`

```text
usage: vcc token check [-h] token

Check token

positional arguments:
  token

options:
  -h, --help  show this help message and exit
```

### `vcc token list`

```text
usage: vcc token list [-h]

List all token info

options:
  -h, --help  show this help message and exit
```

### `vcc token revoke`

```text
usage: vcc token revoke [-h] token

Revoke token

positional arguments:
  token

options:
  -h, --help  show this help message and exit
```
