package aws.validation

import future.keywords.contains
import future.keywords.if
import future.keywords.in

import input

deny_rdspassword contains {
    "msg": "RDS should not specify passwords",
    "details": {
        "rds_with_password": rds_with_password
    }
} if {
    data_resources := [resource |
        some resource in input.planned_values.root_module.resources
        resource.type in {"aws_db_instance"}
    ]

    rds_with_password := [ rds.name | 
        some rds in data_resources
        rds.values.password != null
    ]

    count(rds_with_password) != 0

}