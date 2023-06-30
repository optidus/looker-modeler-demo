view: order_items {
  sql_table_name: `thelook.order_items`
    ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension: inventory_item_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.inventory_item_id ;;
  }



  dimension: product_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.product_id ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.returned_at ;;
  }

  dimension: sale_price {
    type: number
    sql: ${TABLE}.sale_price ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.shipped_at ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: user_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  measure: count_last_28d {
    label: "Count Sold in Trailing 28 Days"
    type: count_distinct
    sql: ${id} ;;
    hidden: yes
    filters:
    {field:created_date
      value: "28 days"
    }}

  measure: order_count {
    view_label: "Orders"
    type: count_distinct
    drill_fields: [detail*]
    sql: ${order_id} ;;
  }

  measure: first_purchase_count {
    view_label: "Orders"
    type: count_distinct
    sql: ${order_id} ;;
    filters: {
      field: order_facts.is_first_purchase
      value: "Yes"
    }
    drill_fields: [user_id, users.name, users.email, order_id, created_date, users.traffic_source]
  }

  dimension: order_id_no_actions {
    label: "Order ID No Actions"
    type: number
    hidden: yes
    sql: ${TABLE}.order_id ;;
  }

  dimension: order_id {
    label: "Order ID"
    type: number
    sql: ${TABLE}.order_id ;;
    action: {
      label: "Send this to slack channel"
      url: "https://hooks.zapier.com/hooks/catch/1662138/tvc3zj/"
      param: {
        name: "user_dash_link"
        value: "/dashboards/ayalascustomerlookupdb?Email={{ users.email._value}}"
      }
      form_param: {
        name: "Message"
        type: textarea
        default: "Hey,
        Could you check out order #{{value}}. It's saying its {{status._value}},
        but the customer is reaching out to us about it.
        ~{{ _user_attributes.first_name}}"
      }
      form_param: {
        name: "Recipient"
        type: select
        default: "zevl"
        option: {
          name: "zevl"
          label: "Zev"
        }
        option: {
          name: "slackdemo"
          label: "Slack Demo User"
        }
      }
      form_param: {
        name: "Channel"
        type: select
        default: "cs"
        option: {
          name: "cs"
          label: "Customer Support"
        }
        option: {
          name: "general"
          label: "General"
        }
      }
    }
    action: {
      label: "Create Order Form"
      url: "https://hooks.zapier.com/hooks/catch/2813548/oosxkej/"
      form_param: {
        name: "Order ID"
        type: string
        default: "{{ order_id._value }}"
      }

      form_param: {
        name: "Name"
        type: string
        default: "{{ users.name._value }}"
      }

      form_param: {
        name: "Email"
        type: string
        default: "{{ _user_attributes.email }}"
      }

      form_param: {
        name: "Item"
        type: string
        default: "{{ products.item_name._value }}"
      }

      form_param: {
        name: "Price"
        type: string
        default: "{{ order_items.sale_price._rendered_value }}"
      }

      form_param: {
        name: "Comments"
        type: string
        default: " Hi {{ users.first_name._value }}, thanks for your business!"
      }
    }
    value_format: "00000"
  }

########## Time Dimensions ##########



  dimension: reporting_period {
    group_label: "Order Date"
    sql: CASE
        WHEN EXTRACT(YEAR from ${created_raw}) = EXTRACT(YEAR from CURRENT_TIMESTAMP())
        AND ${created_raw} < CURRENT_TIMESTAMP()
        THEN 'This Year to Date'

      WHEN EXTRACT(YEAR from ${created_raw}) + 1 = EXTRACT(YEAR from CURRENT_TIMESTAMP())
      AND CAST(FORMAT_TIMESTAMP('%j', ${created_raw}) AS INT64) <= CAST(FORMAT_TIMESTAMP('%j', CURRENT_TIMESTAMP()) AS INT64)
      THEN 'Last Year to Date'

      END
      ;;
  }

  dimension: days_since_sold {
    label: "Days Since Sold"
    hidden: yes
    sql: TIMESTAMP_DIFF(${created_raw},CURRENT_TIMESTAMP(), DAY) ;;
  }

  dimension: months_since_signup {
    label: "Months Since Signup"
    view_label: "Orders"
    type: number
    sql: CAST(FLOOR(TIMESTAMP_DIFF(${created_raw}, ${users.created_raw}, DAY)/30) AS INT64) ;;
  }


########## Logistics ##########

  dimension: days_to_process {
    label: "Days to Process"
    type: number
    sql: CASE
        WHEN ${status} = 'Processing' THEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), ${created_raw}, DAY)*1.0 + 1
        WHEN ${status} IN ('Shipped', 'Complete', 'Returned') THEN TIMESTAMP_DIFF(${shipped_raw}, ${created_raw}, DAY)*1.0
        WHEN ${status} = 'Cancelled' THEN NULL
      END
       ;;
  }


  dimension: shipping_time {
    label: "Shipping Time"
    type: number
    sql: TIMESTAMP_DIFF(${delivered_raw}, ${shipped_raw}, DAY)*1.0 ;;
  }


  measure: average_days_to_process {
    label: "Average Days to Process"
    type: average
    value_format_name: decimal_2
    sql: ${days_to_process} ;;
  }

  measure: average_shipping_time {
    label: "Average Shipping Time"
    type: average
    value_format_name: decimal_2
    sql: ${shipping_time} ;;
  }


########## Financial Information ##########



  dimension: gross_margin {
    label: "Gross Margin"
    type: number
    value_format_name: usd
    sql: ${sale_price} - ${inventory_items.cost};;
  }

  dimension: item_gross_margin_percentage {
    label: "Item Gross Margin Percentage"
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${gross_margin}/NULLIF(${sale_price},0) ;;
  }

  dimension: item_gross_margin_percentage_tier {
    label: "Item Gross Margin Percentage Tier"
    type: tier
    sql: 100*${item_gross_margin_percentage} ;;
    tiers: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
    style: interval
  }

  measure: total_sale_price {
    label: "Total Sale Price"
    type: sum
    value_format_name: usd
    sql: ${sale_price} ;;
    drill_fields: [detail*]
  }

  measure: total_gross_margin {
    label: "Total Gross Margin"
    type: sum
    value_format_name: usd
    sql: ${gross_margin} ;;
    # drill_fields: [detail*]
    drill_fields: [user_id, average_sale_price, total_gross_margin]
  }

  measure: average_sale_price {
    label: "Average Sale Price"
    type: average
    value_format_name: usd
    sql: ${sale_price} ;;
    drill_fields: [detail*]
  }

  measure: median_sale_price {
    label: "Median Sale Price"
    type: median
    value_format_name: usd
    sql: ${sale_price} ;;
    drill_fields: [detail*]
  }

  measure: average_gross_margin {
    label: "Average Gross Margin"
    type: average
    value_format_name: usd
    sql: ${gross_margin} ;;
    drill_fields: [detail*]
  }

  measure: total_gross_margin_percentage {
    label: "Total Gross Margin Percentage"
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${total_gross_margin}/ nullif(${total_sale_price},0) ;;
  }

  measure: average_spend_per_user {
    label: "Average Spend per User"
    type: number
    value_format_name: usd
    sql: 1.0 * ${total_sale_price} / nullif(${users.count},0) ;;
    drill_fields: [detail*]
  }

########## Return Information ##########

  dimension: is_returned {
    label: "Is Returned"
    type: yesno
    sql: ${returned_raw} IS NOT NULL ;;
  }

  measure: returned_count {
    label: "Returned Count"
    type: count_distinct
    sql: ${id} ;;
    filters: {
      field: is_returned
      value: "yes"
    }
    drill_fields: [detail*]
  }

  measure: returned_total_sale_price {
    label: "Returned Total Sale Price"
    type: sum
    value_format_name: usd
    sql: ${sale_price} ;;
    filters: {
      field: is_returned
      value: "yes"
    }
  }

  measure: return_rate {
    label: "Return Rate"
    type: number
    value_format_name: percent_2
    sql: 1.0 * ${returned_count} / nullif(${count},0) ;;
  }

########## Repeat Purchase Facts ##########

  # dimension: days_until_next_order {
  #   label: "Days Until Next Order"
  #   type: number
  #   view_label: "Repeat Purchase Facts"
  #   sql: TIMESTAMP_DIFF(${created_raw},${repeat_purchase_facts.next_order_raw}, DAY) ;;
  # }

  # dimension: repeat_orders_within_30d {
  #   label: "Repeat Orders within 30 Days"
  #   type: yesno
  #   view_label: "Repeat Purchase Facts"
  #   sql: ${days_until_next_order} <= 30 ;;
  # }

  # dimension: repeat_orders_within_15d{
  #   label: "Repeat Orders within 15 Days"
  #   type: yesno
  #   sql:  ${days_until_next_order} <= 15;;
  # }

  # measure: count_with_repeat_purchase_within_30d {
  #   label: "Count with Repeat Purchase within 30 Days"
  #   type: count_distinct
  #   sql: ${id} ;;
  #   view_label: "Repeat Purchase Facts"

  #   filters: {
  #     field: repeat_orders_within_30d
  #     value: "Yes"
  #   }
  # }

  # measure: 30_day_repeat_purchase_rate {
  #   description: "The percentage of customers who purchase again within 30 days"
  #   view_label: "Repeat Purchase Facts"
  #   type: number
  #   value_format_name: percent_1
  #   sql: 1.0 * ${count_with_repeat_purchase_within_30d} / (CASE WHEN ${count} = 0 THEN NULL ELSE ${count} END) ;;
  #   drill_fields: [products.brand, order_count, count_with_repeat_purchase_within_30d]
  # }


  # ----- Sets of fields for drilling ------
  set: detail {
    fields: [
      id,
      users.last_name,
      users.id,
      users.first_name,
      inventory_items.id,
      inventory_items.product_name,
      products.name,
      products.id,
      orders.order_id
    ]
  }
}
