# frozen_string_literal: true

class Framework < Roda
  route 'reports', 'pack_material' do |r| # rubocop:disable Metrics/BlockLength
    # MR PURCHASE ORDERS
    # --------------------------------------------------------------------------
    r.on 'delivery_received', Integer do |id|
      res = CreateJasperReport.call(report_name: 'delivery_received_note',
                                    user: current_user.login_name,
                                    file: 'delivery_received_note',
                                    params: { delivery_id: id,
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'waybill_note', Integer do |id|
      res = CreateJasperReport.call(report_name: 'waybill_note',
                                    user: current_user.login_name,
                                    file: 'waybill_note',
                                    params: { delivery_id: id,
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'delivery_purchase_invoice', Integer do |id|
      res = CreateJasperReport.call(report_name: 'delivery_purchase_invoice',
                                    user: current_user.login_name,
                                    file: 'delivery_purchase_invoice',
                                    params: { delivery_id: id,
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # BULK STOCK ADJUSTMENTS
    # --------------------------------------------------------------------------
    r.on 'stock_adjustment_sheet', Integer do |id|
      res = CreateJasperReport.call(report_name: 'stock_adjustment_sheet',
                                    user: current_user.login_name,
                                    file: 'stock_adjustment_sheet',
                                    params: { delivery_id: id,
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'signed_off_report', Integer do |id|
      res = CreateJasperReport.call(report_name: 'signed_off_report',
                                    user: current_user.login_name,
                                    file: 'signed_off_report',
                                    params: { delivery_id: id,
                                              keep_file: true })
      if res.success
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end
  end
end
