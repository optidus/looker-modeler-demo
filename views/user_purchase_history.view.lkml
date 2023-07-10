view: user_purchase_history {
  derived_table: {
    explore_source: order_items {
      column: user_id { field: order_items.user_id }
      column: order_id {}
      column: created_at {field: order_items.created_raw}
      column: product_id {}
      column: category { field: products.category }
      derived_column: order_sequence_number {
        sql: RANK() OVER (PARTITION BY user_id ORDER BY created_at) ;;
      }
    }
  }
  dimension: user_id {
    description: "user ID"
    label: "User ID"
    type: number
  }
  dimension: order_id {
    description: ""
    label: "order ID"
    type: number
  }
  dimension: created_at {
    description: ""
    label: "Created date"
    type: date
  }
  dimension: product_id {
    description: ""
    label: "Product ID"
    type: number
  }
  dimension: category {
    description: ""
    label: "Product Category"
  }
  dimension: order_sequence_number {
    label: "Order Sequence Number"
    type: number
    sql: ${TABLE}.order_sequence_number ;;
  }
}
